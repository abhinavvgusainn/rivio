import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Subjects under the Notes (PDF organizer) section.
/// Must never be shared with FlashcardSubjects.
class NoteSubjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// A single PDF reference stored under a NoteSubject.
/// We store only the file's path/URI + metadata, never the raw bytes.
class NoteFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(NoteSubjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Subjects under Flashcards. Independent from NoteSubjects.
class FlashcardSubjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class FlashcardDecks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer()
      .references(FlashcardSubjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Flashcards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deckId =>
      integer().references(FlashcardDecks, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()();
  TextColumn get back => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  IntColumn get timesReviewed => integer().withDefault(const Constant(0))();
}

/// One row per meaningful study action (a finished pomodoro,
/// a finished flashcard review pass). Opening the app does NOT
/// create a row here.
enum StudySessionType { pomodoro, flashcardReview }

class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type =>
      intEnum<StudySessionType>()(); // stored as its enum index
  IntColumn get durationSeconds => integer()();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  NoteSubjects,
  NoteFiles,
  FlashcardSubjects,
  FlashcardDecks,
  Flashcards,
  StudySessions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bump this whenever a table shape changes.
  @override
  int get schemaVersion => 1;

  // ---------------- Notes ----------------

  Stream<List<NoteSubject>> watchNoteSubjects() =>
      select(noteSubjects).watch();

  Future<int> createNoteSubject(String name) =>
      into(noteSubjects).insert(NoteSubjectsCompanion.insert(name: name));

  Future<void> deleteNoteSubject(int id) =>
      (delete(noteSubjects)..where((t) => t.id.equals(id))).go();

  Stream<List<NoteFile>> watchNoteFiles(int subjectId) =>
      (select(noteFiles)..where((t) => t.subjectId.equals(subjectId)))
          .watch();

  Future<int> addNoteFile({
    required int subjectId,
    required String fileName,
    required String filePath,
  }) =>
      into(noteFiles).insert(NoteFilesCompanion.insert(
        subjectId: subjectId,
        fileName: fileName,
        filePath: filePath,
      ));

  Future<void> deleteNoteFile(int id) =>
      (delete(noteFiles)..where((t) => t.id.equals(id))).go();

  // ---------------- Flashcards ----------------

  Stream<List<FlashcardSubject>> watchFlashcardSubjects() =>
      select(flashcardSubjects).watch();

  Future<int> createFlashcardSubject(String name) => into(flashcardSubjects)
      .insert(FlashcardSubjectsCompanion.insert(name: name));

  Future<void> deleteFlashcardSubject(int id) =>
      (delete(flashcardSubjects)..where((t) => t.id.equals(id))).go();

  Stream<List<FlashcardDeck>> watchDecks(int subjectId) =>
      (select(flashcardDecks)..where((t) => t.subjectId.equals(subjectId)))
          .watch();

  Future<int> createDeck({required int subjectId, required String name}) =>
      into(flashcardDecks).insert(
        FlashcardDecksCompanion.insert(subjectId: subjectId, name: name),
      );

  Future<void> deleteDeck(int id) =>
      (delete(flashcardDecks)..where((t) => t.id.equals(id))).go();

  Stream<List<Flashcard>> watchCards(int deckId) =>
      (select(flashcards)..where((t) => t.deckId.equals(deckId))).watch();

  Future<int> addCard({
    required int deckId,
    required String front,
    required String back,
  }) =>
      into(flashcards).insert(FlashcardsCompanion.insert(
        deckId: deckId,
        front: front,
        back: back,
      ));

  Future<void> updateCard(Flashcard card) =>
      update(flashcards).replace(card);

  Future<void> deleteCard(int id) =>
      (delete(flashcards)..where((t) => t.id.equals(id))).go();

  Future<void> markCardReviewed(int id) => (update(flashcards)
        ..where((t) => t.id.equals(id)))
      .write(FlashcardsCompanion(
    lastReviewedAt: Value(DateTime.now()),
  ));

  // ---------------- Study sessions / statistics ----------------

  Future<int> logStudySession({
    required StudySessionType type,
    required int durationSeconds,
  }) =>
      into(studySessions).insert(StudySessionsCompanion.insert(
        type: type,
        durationSeconds: durationSeconds,
      ));

  Stream<List<StudySession>> watchAllSessions() =>
      (select(studySessions)
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .watch();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rivio.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
