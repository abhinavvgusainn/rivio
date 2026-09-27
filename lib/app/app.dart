import 'dart:async';

import 'package:flutter/material.dart';

import '../database/database.dart';
import '../features/flashcards/flashcards_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/pomodoro/pomodoro_screen.dart';
import '../services/interaction_feedback.dart';
import 'theme.dart';

class RivioApp extends StatefulWidget {
  const RivioApp({super.key, this.database});
  final AppDatabase? database;

  @override
  State<RivioApp> createState() => _RivioAppState();
}

class _RivioAppState extends State<RivioApp> {
  late final AppDatabase _database;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();
    _ownsDatabase = widget.database == null;
    _database = widget.database ?? AppDatabase();
  }

  @override
  void dispose() {
    if (_ownsDatabase) unawaited(_database.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Rivio',
    theme: RivioTheme.light,
    builder: (context, child) => Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => InteractionFeedback.stopSound(),
      child: child ?? const SizedBox.shrink(),
    ),
    home: MainNavigation(database: _database),
  );
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, required this.database});
  final AppDatabase database;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(database: widget.database),
          PomodoroScreen(database: widget.database),
          NotesScreen(database: widget.database),
          FlashcardsScreen(database: widget.database),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer_rounded),
          label: 'Timer',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description_rounded),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Icons.style_outlined),
          selectedIcon: Icon(Icons.style_rounded),
          label: 'Flashcards',
        ),
      ],
    ),
  );
}
