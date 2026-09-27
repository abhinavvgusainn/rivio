import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivio/database/database.dart';
import 'package:rivio/services/statistics_service.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('card answers persist review history and spaced repetition', () async {
    final subjectId = await database.createFlashcardSubject('Economics');
    final deckId = await database.createDeck(
      subjectId: subjectId,
      name: 'Chapter 1',
    );
    final cardId = await database.addCard(
      deckId: deckId,
      front: 'Define scarcity',
      back: 'Limited resources',
    );

    await database.markCardReviewed(cardId, known: true);
    await database.markCardReviewed(cardId, known: true);
    var card = await (database.select(
      database.flashcards,
    )..where((row) => row.id.equals(cardId))).getSingle();
    expect(card.timesReviewed, 2);
    expect(card.consecutiveCorrect, 2);
    expect(card.nextReviewAt!.isAfter(DateTime.now()), isTrue);

    await database.markCardReviewed(cardId, known: false);
    card = await (database.select(
      database.flashcards,
    )..where((row) => row.id.equals(cardId))).getSingle();
    expect(card.timesReviewed, 3);
    expect(card.consecutiveCorrect, 0);
    expect(
      card.nextReviewAt!.isBefore(
        DateTime.now().add(const Duration(seconds: 1)),
      ),
      isTrue,
    );

    final effort = (await database.watchSubjectEfforts().first).single;
    expect(effort.cardsCreated, 1);
    expect(effort.cardsReviewed, 3);
    expect(effort.effortScore, 7);
    expect((await database.watchReviewEvents().first), hasLength(3));
  });

  test(
    'study sessions keep focus and subject review counts separate',
    () async {
      final subjectId = await database.createFlashcardSubject('Statistics');
      await database.logStudySession(
        type: StudySessionType.pomodoro,
        durationSeconds: 1500,
      );
      await database.logStudySession(
        type: StudySessionType.flashcardReview,
        durationSeconds: 240,
        cardsReviewed: 4,
        subjectId: subjectId,
      );

      final sessions = await database.watchAllSessions().first;
      expect(sessions, hasLength(2));
      expect(
        sessions
            .where((session) => session.type == StudySessionType.pomodoro)
            .single
            .durationSeconds,
        1500,
      );
      expect(
        sessions
            .where(
              (session) => session.type == StudySessionType.flashcardReview,
            )
            .single
            .cardsReviewed,
        4,
      );
      expect(
        sessions
            .where(
              (session) => session.type == StudySessionType.flashcardReview,
            )
            .single
            .subjectId,
        subjectId,
      );
    },
  );

  test('activity combines completed timer and card review effort', () async {
    final subjectId = await database.createFlashcardSubject('Biology');
    final deckId = await database.createDeck(
      subjectId: subjectId,
      name: 'Cells',
    );
    final cardId = await database.addCard(
      deckId: deckId,
      front: 'What is a cell?',
      back: 'The basic unit of life.',
    );
    await database.markCardReviewed(cardId, known: true);
    await database.logStudySession(
      type: StudySessionType.pomodoro,
      durationSeconds: 1500,
    );
    await database.logStudySession(
      type: StudySessionType.flashcardReview,
      durationSeconds: 240,
      cardsReviewed: 1,
      subjectId: subjectId,
    );
    await database.logStudySession(
      type: StudySessionType.pomodoro,
      durationSeconds: 600,
      completed: false,
    );

    final stats = HomeStatistics.fromSessions(
      await database.watchAllSessions().first,
      await database.watchReviewEvents().first,
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final key =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    expect(stats.activity[key]!.timerMinutes, 35);
    expect(stats.activity[key]!.reviewMinutes, 4);
    expect(stats.activity[key]!.cardsReviewed, 1);
    expect(stats.currentStreak, 1);
    expect(stats.todayFocusSeconds, 2100);
    expect(stats.totalFocusSeconds, 2100);
    expect(stats.focusSessions, 1);
  });
}
