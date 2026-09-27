import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivio/app/app.dart';
import 'package:rivio/database/database.dart';

void main() {
  testWidgets('reference screens fit a phone-sized viewport', (tester) async {
    tester.view.physicalSize = const Size(450, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    void expectNoLayoutError() {
      final error = tester.takeException();
      final details = error is FlutterError ? error.toStringDeep() : '$error';
      expect(error, isNull, reason: details);
    }

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final subjects = <int>[];
    for (final name in [
      'Financial Accounting',
      'Economics',
      'Data Mining',
      'Statistics',
    ]) {
      final id = await database.createFlashcardSubject(name);
      subjects.add(id);
      final deckId = await database.createDeck(
        subjectId: id,
        name: 'Chapter 1',
      );
      final cardId = await database.addCard(
        deckId: deckId,
        front: 'What is $name?',
        back: 'A study subject.',
      );
      await database.markCardReviewed(cardId, known: true);
      if (subjects.length == 1) {
        await database.logStudySession(
          type: StudySessionType.flashcardReview,
          durationSeconds: 780,
          cardsReviewed: 1,
          subjectId: id,
        );
      }
    }
    await database.logStudySession(
      type: StudySessionType.pomodoro,
      durationSeconds: 2700,
    );
    for (final name in [
      'Financial Accounting',
      'Economics',
      'Data Mining',
      'Statistics',
    ]) {
      await database.createNoteSubject(name);
    }

    await tester.pumpWidget(RivioApp(database: database));
    await tester.pumpAndSettle();
    expectNoLayoutError();
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expectNoLayoutError();
    tester.view.physicalSize = const Size(450, 980);
    await tester.pumpAndSettle();
    for (final tab in ['Timer', 'Notes', 'Flashcards']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expectNoLayoutError();
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();
      expectNoLayoutError();
      tester.view.physicalSize = const Size(450, 980);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
