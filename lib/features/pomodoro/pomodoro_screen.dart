import 'dart:async';

import 'package:flutter/material.dart';

import '../../database/database.dart';
import 'widgets/timer_controls.dart';
import 'widgets/timer_display.dart';

/// A single 25-minute focus timer. Completing a session (letting it
/// run to zero) logs a [StudySession] row that Home's statistics
/// read from. Pausing/resetting early does not log anything —
/// opening the app or starting a timer alone should not count as
/// studying.
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key, required this.database});

  final AppDatabase database;

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const _focusDuration = Duration(minutes: 25);

  Duration _remaining = _focusDuration;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleStartPause() {
    if (_isRunning) {
      _pause();
    } else {
      _start();
    }
  }

  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        _completeSession();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remaining = _focusDuration;
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    await widget.database.logStudySession(
      type: StudySessionType.pomodoro,
      durationSeconds: _focusDuration.inSeconds,
    );
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _remaining = _focusDuration;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Focus session complete 🎉')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TimerDisplay(remaining: _remaining, total: _focusDuration),
            const SizedBox(height: 40),
            TimerControls(
              isRunning: _isRunning,
              onStartPause: _toggleStartPause,
              onReset: _reset,
            ),
          ],
        ),
      ),
    );
  }
}
