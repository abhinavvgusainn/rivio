import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivio/app/app.dart';
import 'package:rivio/database/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('tabs open the real study screens', (tester) async {
    await tester.pumpWidget(RivioApp(database: database));
    await tester.pumpAndSettle();
    expect(find.text('Study Distribution'), findsOneWidget);

    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();
    expect(find.text('Pomodoro'), findsWidgets);
    expect(find.text('Start Session'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Notes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Subject Folders'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Flashcards'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add Subject'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('the shared app bar scrolls away and returns on reverse scroll', (
    tester,
  ) async {
    await tester.pumpWidget(RivioApp(database: database));
    await tester.pumpAndSettle();
    expect(find.text('StudyFlow'), findsOneWidget);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('StudyFlow'), findsNothing);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 140),
    );
    await tester.pumpAndSettle();
    expect(find.text('StudyFlow'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a completed deck review records the card result', (
    tester,
  ) async {
    final subjectId = await database.createFlashcardSubject('Biology');
    final deckId = await database.createDeck(
      subjectId: subjectId,
      name: 'Cells',
    );
    await database.addCard(
      deckId: deckId,
      front: 'What is a cell?',
      back: 'The basic unit of life.',
    );
    await tester.pumpWidget(RivioApp(database: database));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Flashcards'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Study'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Study'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('What is a cell?'));
    await tester.pumpAndSettle();
    expect(find.text('The basic unit of life.'), findsOneWidget);
    await tester.tap(find.text('Knew it'));
    await tester.pumpAndSettle();
    expect(find.text('Deck complete!'), findsOneWidget);
    await tester.tap(find.text('That felt good'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final reviews = await database.select(database.flashcardReviewEvents).get();
    final sessions = await database.select(database.studySessions).get();
    expect(reviews.single.known, isTrue);
    expect(reviews.single.subjectId, subjectId);
    expect(sessions.single.cardsReviewed, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('timer settings and modes remain interactive', (tester) async {
    await tester.pumpWidget(RivioApp(database: database));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Timer'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '1');
    await tester.enterText(fields.at(1), '1');
    await tester.enterText(fields.at(2), '2');
    await tester.enterText(fields.at(3), '1');
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView).last, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('01:00'), findsOneWidget);

    await tester.tap(find.text('Long Break'));
    await tester.pumpAndSettle();
    expect(find.text('Break Time'), findsOneWidget);
    expect(find.text('02:00'), findsOneWidget);

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Session Settings'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Focus Time'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('keyboard dismissal keeps the name dialog mounted safely', (
    tester,
  ) async {
    await tester.pumpWidget(RivioApp(database: database));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Notes'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add Subject'));
    await tester.tap(find.text('Add Subject'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Biology');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(await database.select(database.noteSubjects).get(), hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
