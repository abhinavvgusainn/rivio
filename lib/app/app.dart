import 'package:flutter/material.dart';

import '../database/database.dart';
import '../features/flashcards/flashcards_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/pomodoro/pomodoro_screen.dart';
import 'theme.dart';

/// Root widget. Owns the single [AppDatabase] instance and the
/// bottom navigation between the four main sections.
class RivioApp extends StatefulWidget {
  const RivioApp({super.key});

  @override
  State<RivioApp> createState() => _RivioAppState();
}

class _RivioAppState extends State<RivioApp> {
  late final AppDatabase _database;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rivio',
      debugShowCheckedModeBanner: false,
      theme: RivioTheme.light,
      home: RivioHome(database: _database),
    );
  }
}

class RivioHome extends StatefulWidget {
  const RivioHome({super.key, required this.database});

  final AppDatabase database;

  @override
  State<RivioHome> createState() => _RivioHomeState();
}

class _RivioHomeState extends State<RivioHome> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.timer_outlined),
      selectedIcon: Icon(Icons.timer),
      label: 'Pomodoro',
    ),
    NavigationDestination(
      icon: Icon(Icons.picture_as_pdf_outlined),
      selectedIcon: Icon(Icons.picture_as_pdf),
      label: 'Notes',
    ),
    NavigationDestination(
      icon: Icon(Icons.style_outlined),
      selectedIcon: Icon(Icons.style),
      label: 'Flashcards',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final db = widget.database;

    return Scaffold(
      // IndexedStack keeps each tab's scroll position / in-flight
      // state alive when switching tabs, per the product spec.
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(database: db),
            PomodoroScreen(database: db),
            NotesScreen(database: db),
            FlashcardsScreen(database: db),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
