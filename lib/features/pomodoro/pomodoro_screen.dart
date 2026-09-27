import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/study_widgets.dart';
import '../../database/database.dart';
import '../../services/interaction_feedback.dart';
import '../flashcards/review_screen.dart';
import 'widgets/timer_controls.dart';
import 'widgets/timer_display.dart';

enum _TimerMode { pomodoro, shortBreak, longBreak, custom }

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key, required this.database});
  final AppDatabase database;

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  int _longBreakMinutes = 15;
  int _cycleGoal = 4;
  int _completedCycles = 0;
  bool _bellCue = true;
  bool _running = false;
  _TimerMode _mode = _TimerMode.pomodoro;
  Duration _remaining = const Duration(minutes: 25);
  DateTime? _deadline;
  DateTime? _runStartedAt;
  Duration _runDuration = Duration.zero;
  Timer? _ticker;

  Duration get _duration => switch (_mode) {
    _TimerMode.pomodoro ||
    _TimerMode.custom => Duration(minutes: _focusMinutes),
    _TimerMode.shortBreak => Duration(minutes: _breakMinutes),
    _TimerMode.longBreak => Duration(minutes: _longBreakMinutes),
  };

  bool get _isFocus =>
      _mode == _TimerMode.pomodoro || _mode == _TimerMode.custom;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _selectMode(_TimerMode mode) {
    if (_running) return;
    setState(() {
      _mode = mode;
      _remaining = Duration(
        minutes: switch (mode) {
          _TimerMode.pomodoro || _TimerMode.custom => _focusMinutes,
          _TimerMode.shortBreak => _breakMinutes,
          _TimerMode.longBreak => _longBreakMinutes,
        },
      );
    });
    InteractionFeedback.tap();
    if (mode == _TimerMode.custom) _editSettings();
  }

  void _toggleTimer() {
    if (_running) {
      final now = DateTime.now();
      final left = _deadline!.difference(now);
      if (left <= Duration.zero) {
        unawaited(_completeTimer());
        return;
      }
      _ticker?.cancel();
      unawaited(_logFocusTime(_activeRunSeconds(now), completed: false));
      setState(() {
        _running = false;
        _deadline = null;
        _runStartedAt = null;
        _remaining = left;
      });
      InteractionFeedback.tap();
      return;
    }
    if (_remaining.inSeconds <= 0) setState(() => _remaining = _duration);
    setState(() {
      _running = true;
      _runStartedAt = DateTime.now();
      _runDuration = _remaining;
      _deadline = _runStartedAt!.add(_remaining);
    });
    InteractionFeedback.tap();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _deadline!.difference(DateTime.now());
      if (left <= Duration.zero) {
        _completeTimer();
      } else if (mounted) {
        setState(() => _remaining = left);
      }
    });
  }

  Future<void> _reset() async {
    final secondsToLog = _running && _isFocus
        ? _activeRunSeconds(DateTime.now())
        : 0;
    _ticker?.cancel();
    setState(() {
      _running = false;
      _deadline = null;
      _runStartedAt = null;
      _remaining = _duration;
    });
    await _logFocusTime(secondsToLog, completed: false);
    InteractionFeedback.tap();
  }

  Future<void> _completeTimer() async {
    _ticker?.cancel();
    final finishedFocus = _isFocus;
    if (finishedFocus) {
      await _logFocusTime(_activeRunSeconds(DateTime.now()));
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _deadline = null;
      _runStartedAt = null;
      if (finishedFocus) {
        _completedCycles++;
        _mode = _completedCycles >= _cycleGoal
            ? _TimerMode.longBreak
            : _TimerMode.shortBreak;
      } else {
        if (_mode == _TimerMode.longBreak) _completedCycles = 0;
        _mode = _TimerMode.pomodoro;
      }
      _remaining = _duration;
    });
    InteractionFeedback.celebrate(sound: _bellCue);
    if (finishedFocus) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DeckCelebrationDialog(
          title: 'Focus session complete!',
          subtitle:
              'You made room for real progress. Take a restorative break.',
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Break complete. Ready for another focus session?'),
          ),
        );
      }
    }
  }

  int _activeRunSeconds(DateTime now) {
    final startedAt = _runStartedAt;
    if (startedAt == null) return 0;
    return now.difference(startedAt).inSeconds.clamp(0, _runDuration.inSeconds);
  }

  Future<void> _logFocusTime(int seconds, {bool completed = true}) async {
    if (!_isFocus || seconds <= 0) return;
    await widget.database.logStudySession(
      type: StudySessionType.pomodoro,
      durationSeconds: seconds,
      completed: completed,
    );
  }

  Future<void> _editSettings() async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (_) => _SessionSettingsDialog(
        focusMinutes: _focusMinutes,
        shortBreakMinutes: _breakMinutes,
        longBreakMinutes: _longBreakMinutes,
        cycleGoal: _cycleGoal,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _focusMinutes = result[0];
      _breakMinutes = result[1];
      _longBreakMinutes = result[2];
      _cycleGoal = result[3];
      _completedCycles = _completedCycles % _cycleGoal;
      _completedCycles = _completedCycles.clamp(0, _cycleGoal);
      _remaining = _duration;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: StreamBuilder<List<StudySession>>(
      stream: widget.database.watchAllSessions(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <StudySession>[];
        final today = DateUtils.dateOnly(DateTime.now());
        final todayTimerSessions = sessions
            .where(
              (session) =>
                  session.type == StudySessionType.pomodoro &&
                  DateUtils.isSameDay(session.completedAt, today),
            )
            .toList();
        final todayFocus = todayTimerSessions
            .where((session) => session.completed)
            .toList();
        final todaySeconds = todayTimerSessions.fold<int>(
          0,
          (sum, session) => sum + session.durationSeconds,
        );
        final progress = (todaySeconds / (4 * 3600)).clamp(0.0, 1.0);
        final hours = todaySeconds ~/ 3600;
        final minutes = (todaySeconds % 3600) ~/ 60;
        final dailyLabel = todaySeconds > 0 && minutes == 0 && hours == 0
            ? '<1m'
            : hours == 0
            ? '${minutes}m'
            : '${hours}h ${minutes}m';
        return CustomScrollView(
          slivers: [
            const StudySliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 25),
              sliver: SliverList.list(
                children: [
                  const Text(
                    'Pomodoro',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _modeSelector(),
                  const SizedBox(height: 22),
                  TimerDisplay(
                    remaining: _remaining,
                    total: _duration,
                    label: _isFocus ? 'Focus Time' : 'Break Time',
                    color: _isFocus ? RivioColors.green : RivioColors.coral,
                  ),
                  const SizedBox(height: 5),
                  TimerControls(
                    isRunning: _running,
                    onStartPause: _toggleTimer,
                    onReset: _reset,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _bellCue = !_bellCue);
                        InteractionFeedback.tap();
                      },
                      icon: Icon(
                        _bellCue
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                      ),
                      label: Text(_bellCue ? 'Bell Cue: On' : 'Bell Cue: Off'),
                      style: TextButton.styleFrom(
                        foregroundColor: RivioColors.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          SectionHeading(
                            title: 'Session Settings',
                            trailing: TextButton(
                              onPressed: _running ? null : _editSettings,
                              child: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              Expanded(
                                child: _settingTile(
                                  'Focus',
                                  '$_focusMinutes min',
                                  'Standard',
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _settingTile(
                                  'Break',
                                  '$_breakMinutes min',
                                  'Short rest',
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _settingTile(
                                  'Cycles',
                                  '$_cycleGoal sets',
                                  '$_completedCycles done',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeading(
                    title: 'Today',
                    trailing: Text(
                      'Daily Target: 4h',
                      style: const TextStyle(
                        color: RivioColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 116,
                    child: Row(
                      children: [
                        Expanded(
                          child: _todayMetric(
                            Icons.check_circle_outline,
                            '${todayFocus.length}',
                            'Sessions',
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _todayMetric(
                            Icons.schedule,
                            dailyLabel,
                            'Focus Time',
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _todayMetric(
                            Icons.donut_large,
                            '${(progress * 100).round()}%',
                            'Completion',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cycle ${_completedCycles == 0 ? 1 : _completedCycles} of $_cycleGoal',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RivioColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _modeSelector() => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F3F1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: RivioColors.border),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _modePill(_TimerMode.pomodoro, 'Pomodoro'),
          _modePill(_TimerMode.shortBreak, 'Short Break'),
          _modePill(_TimerMode.longBreak, 'Long Break'),
          _modePill(_TimerMode.custom, 'Custom'),
        ],
      ),
    ),
  );

  Widget _modePill(_TimerMode mode, String text) {
    final selected = _mode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        showCheckmark: false,
        onSelected: _running ? null : (_) => _selectMode(mode),
        selectedColor: RivioColors.green,
        labelStyle: TextStyle(
          color: selected ? Colors.white : RivioColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        side: BorderSide.none,
      ),
    );
  }

  Widget _settingTile(String title, String value, String subtitle) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4F2),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE0E7E2)),
    ),
    child: Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: RivioColors.green, fontSize: 10),
        ),
      ],
    ),
  );

  Widget _todayMetric(IconData icon, String value, String label) => Card(
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: RivioColors.mintSoft,
            child: Icon(icon, color: RivioColors.green, size: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(
              color: RivioColors.secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SessionSettingsDialog extends StatefulWidget {
  const _SessionSettingsDialog({
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.cycleGoal,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int cycleGoal;

  @override
  State<_SessionSettingsDialog> createState() => _SessionSettingsDialogState();
}

class _SessionSettingsDialogState extends State<_SessionSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _focus = TextEditingController(text: '${widget.focusMinutes}');
  late final _shortBreak = TextEditingController(
    text: '${widget.shortBreakMinutes}',
  );
  late final _longBreak = TextEditingController(
    text: '${widget.longBreakMinutes}',
  );
  late final _cycles = TextEditingController(text: '${widget.cycleGoal}');

  @override
  void dispose() {
    _focus.dispose();
    _shortBreak.dispose();
    _longBreak.dispose();
    _cycles.dispose();
    super.dispose();
  }

  Widget _minuteField(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, suffixText: 'min'),
    validator: (value) {
      final parsed = int.tryParse(value ?? '');
      return parsed == null || parsed < min || parsed > max
          ? 'Enter a value from $min to $max'
          : null;
    },
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Session Settings'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _minuteField(_focus, 'Focus length (minutes)', 1, 180),
            const SizedBox(height: 10),
            _minuteField(_shortBreak, 'Short break (minutes)', 1, 60),
            const SizedBox(height: 10),
            _minuteField(_longBreak, 'Long break (minutes)', 1, 90),
            const SizedBox(height: 10),
            _minuteField(_cycles, 'Focus sessions per cycle', 1, 12),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, [
              int.parse(_focus.text),
              int.parse(_shortBreak.text),
              int.parse(_longBreak.text),
              int.parse(_cycles.text),
            ]);
          }
        },
        child: const Text('Save settings'),
      ),
    ],
  );
}
