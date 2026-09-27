import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class NoteSubjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get colorHex => text().withDefault(const Constant('#15825B'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class NoteFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(NoteSubjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

class FlashcardSubjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get colorHex => text().withDefault(const Constant('#16845B'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class FlashcardDecks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().references(
    FlashcardSubjects,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Flashcards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deckId =>
      integer().references(FlashcardDecks, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()();
  TextColumn get back => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  IntColumn get timesReviewed => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveCorrect =>
      integer().withDefault(const Constant(0))();
}

class FlashcardReviewEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId =>
      integer().references(Flashcards, #id, onDelete: KeyAction.cascade)();
  IntColumn get subjectId => integer().references(
    FlashcardSubjects,
    #id,
    onDelete: KeyAction.cascade,
  )();
  BoolColumn get known => boolean()();
  DateTimeColumn get reviewedAt => dateTime().withDefault(currentDateAndTime)();
}

enum StudySessionType { pomodoro, flashcardReview }

class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<StudySessionType>()();
  IntColumn get durationSeconds => integer()();
  IntColumn get cardsReviewed => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(true))();
  IntColumn get subjectId => integer().nullable().references(
    FlashcardSubjects,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class SubjectEffort {
  const SubjectEffort({
    required this.subjectId,
    required this.subject,
    required this.cardsCreated,
    required this.cardsReviewed,
  });

  final int subjectId;
  final String subject;
  final int cardsCreated;
  final int cardsReviewed;

  int get effortScore => cardsCreated + cardsReviewed * 2;
}

const _subjectColors = [
  '#087447',
  '#3487B7',
  '#8F66B5',
  '#C85D55',
  '#BB861D',
  '#5C7196',
];

@DriftDatabase(
  tables: [
    NoteSubjects,
    NoteFiles,
    FlashcardSubjects,
    FlashcardDecks,
    Flashcards,
    FlashcardReviewEvents,
    StudySessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(noteSubjects, noteSubjects.colorHex);
        await migrator.addColumn(flashcardSubjects, flashcardSubjects.colorHex);
        await migrator.addColumn(flashcards, flashcards.nextReviewAt);
        await migrator.addColumn(flashcards, flashcards.consecutiveCorrect);
        await migrator.addColumn(studySessions, studySessions.cardsReviewed);
        await migrator.addColumn(studySessions, studySessions.subjectId);
        await migrator.createTable(flashcardReviewEvents);
        for (
          var colorIndex = 0;
          colorIndex < _subjectColors.length;
          colorIndex++
        ) {
          final noteColor = _subjectColors[colorIndex];
          final flashcardColor = _subjectColors[colorIndex];
          await customStatement(
            'UPDATE note_subjects SET color_hex = ? '
            'WHERE color_hex = ? AND (id - 1) % ${_subjectColors.length} = ?',
            [noteColor, '#15825B', colorIndex],
          );
          await customStatement(
            'UPDATE flashcard_subjects SET color_hex = ? '
            'WHERE color_hex = ? AND (id - 1) % ${_subjectColors.length} = ?',
            [flashcardColor, '#16845B', colorIndex],
          );
        }
      }
      if (from < 3) {
        await migrator.addColumn(studySessions, studySessions.completed);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Stream<List<NoteSubject>> watchNoteSubjects() => select(noteSubjects).watch();

  Future<int> createNoteSubject(String name) async {
    final id = await into(noteSubjects)
        .insert(NoteSubjectsCompanion.insert(name: name.trim()));
    await (update(noteSubjects)..where((table) => table.id.equals(id))).write(
      NoteSubjectsCompanion(
        colorHex: Value(_subjectColors[(id - 1) % _subjectColors.length]),
      ),
    );
    return id;
  }

  Future<void> deleteNoteSubject(int id) =>
      (delete(noteSubjects)..where((table) => table.id.equals(id))).go();

  Stream<List<NoteFile>> watchNoteFiles(int subjectId) => (select(
    noteFiles,
  )..where((table) => table.subjectId.equals(subjectId))).watch();

  Stream<List<NoteFile>> watchAllNoteFiles() => (select(
    noteFiles,
  )..orderBy([(table) => OrderingTerm.desc(table.addedAt)])).watch();

  Future<int> addNoteFile({
    required int subjectId,
    required String fileName,
    required String filePath,
  }) => into(noteFiles).insert(
    NoteFilesCompanion.insert(
      subjectId: subjectId,
      fileName: fileName,
      filePath: filePath,
    ),
  );

  Future<void> deleteNoteFile(int id) =>
      (delete(noteFiles)..where((table) => table.id.equals(id))).go();

  Stream<List<FlashcardSubject>> watchFlashcardSubjects() =>
      select(flashcardSubjects).watch();

  Future<int> createFlashcardSubject(String name) async {
    final id = await into(flashcardSubjects)
        .insert(FlashcardSubjectsCompanion.insert(name: name.trim()));
    await (update(
      flashcardSubjects,
    )..where((table) => table.id.equals(id))).write(
      FlashcardSubjectsCompanion(
        colorHex: Value(_subjectColors[(id - 1) % _subjectColors.length]),
      ),
    );
    return id;
  }

  Future<void> deleteFlashcardSubject(int id) =>
      (delete(flashcardSubjects)..where((table) => table.id.equals(id))).go();

  Stream<List<FlashcardDeck>> watchDecks(int subjectId) => (select(
    flashcardDecks,
  )..where((table) => table.subjectId.equals(subjectId))).watch();

  Future<int> createDeck({required int subjectId, required String name}) =>
      into(flashcardDecks).insert(
        FlashcardDecksCompanion.insert(subjectId: subjectId, name: name.trim()),
      );

  Future<void> updateDeck(FlashcardDeck deck) =>
      update(flashcardDecks).replace(deck);

  Future<void> deleteDeck(int id) =>
      (delete(flashcardDecks)..where((table) => table.id.equals(id))).go();

  Stream<List<Flashcard>> watchCards(int deckId) => (select(
    flashcards,
  )..where((table) => table.deckId.equals(deckId))).watch();

  Future<int> addCard({
    required int deckId,
    required String front,
    required String back,
  }) => into(flashcards).insert(
    FlashcardsCompanion.insert(
      deckId: deckId,
      front: front.trim(),
      back: back.trim(),
    ),
  );

  Future<void> updateCard(Flashcard card) => update(flashcards).replace(card);

  Future<void> deleteCard(int id) =>
      (delete(flashcards)..where((table) => table.id.equals(id))).go();

  Future<void> markCardReviewed(int id, {required bool known}) async {
    await transaction(() async {
      final card = await (select(
        flashcards,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (card == null) return;
      final now = DateTime.now();
      final streak = known ? card.consecutiveCorrect + 1 : 0;
      const intervals = [1, 3, 7, 14, 30];
      final nextReviewAt = known
          ? now.add(
              Duration(
                days: intervals[(streak - 1).clamp(0, intervals.length - 1)],
              ),
            )
          : now;
      await (update(flashcards)..where((table) => table.id.equals(id))).write(
        FlashcardsCompanion(
          lastReviewedAt: Value(now),
          nextReviewAt: Value(nextReviewAt),
          timesReviewed: Value(card.timesReviewed + 1),
          consecutiveCorrect: Value(streak),
        ),
      );
      final deck = await (select(
        flashcardDecks,
      )..where((table) => table.id.equals(card.deckId))).getSingle();
      await into(flashcardReviewEvents).insert(
        FlashcardReviewEventsCompanion.insert(
          cardId: card.id,
          subjectId: deck.subjectId,
          known: known,
          reviewedAt: Value(now),
        ),
      );
    });
  }

  Stream<List<SubjectEffort>> watchSubjectEfforts({DateTime? since}) {
    final madeFilter = since == null ? '' : 'AND cards.created_at >= ?';
    final reviewFilter = since == null ? '' : 'AND reviews.reviewed_at >= ?';
    final variables = since == null
        ? <Variable>[]
        : [Variable.withDateTime(since), Variable.withDateTime(since)];
    return customSelect(
      'SELECT subjects.id AS subject_id, subjects.name AS subject, '
      '(SELECT COUNT(*) FROM flashcards AS cards '
      'JOIN flashcard_decks AS decks ON decks.id = cards.deck_id '
      'WHERE decks.subject_id = subjects.id $madeFilter) AS cards_created, '
      '(SELECT COUNT(*) FROM flashcard_review_events AS reviews '
      'WHERE reviews.subject_id = subjects.id $reviewFilter) AS cards_reviewed '
      'FROM flashcard_subjects AS subjects ORDER BY subjects.name',
      variables: variables,
      readsFrom: {
        flashcardSubjects,
        flashcardDecks,
        flashcards,
        flashcardReviewEvents,
      },
    ).watch().map(
      (rows) => rows
          .map(
            (row) => SubjectEffort(
              subjectId: row.read<int>('subject_id'),
              subject: row.read<String>('subject'),
              cardsCreated: row.read<int>('cards_created'),
              cardsReviewed: row.read<int>('cards_reviewed'),
            ),
          )
          .toList(),
    );
  }

  Future<int> logStudySession({
    required StudySessionType type,
    required int durationSeconds,
    int cardsReviewed = 0,
    int? subjectId,
    bool completed = true,
  }) => into(studySessions).insert(
    StudySessionsCompanion.insert(
      type: type,
      durationSeconds: durationSeconds,
      cardsReviewed: Value(cardsReviewed),
      completed: Value(completed),
      subjectId: Value(subjectId),
    ),
  );

  Stream<List<StudySession>> watchAllSessions() => (select(
    studySessions,
  )..orderBy([(table) => OrderingTerm.desc(table.completedAt)])).watch();

  Stream<List<FlashcardReviewEvent>> watchReviewEvents() =>
      select(flashcardReviewEvents).watch();
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationDocumentsDirectory();
  return NativeDatabase.createInBackground(
    File(p.join(directory.path, 'rivio.sqlite')),
  );
});
