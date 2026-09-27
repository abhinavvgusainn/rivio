import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Start/Pause + Reset controls for the Pomodoro timer.
class TimerControls extends StatelessWidget {
  const TimerControls({
    super.key,
    required this.isRunning,
    required this.onStartPause,
    required this.onReset,
  });

  final bool isRunning;
  final VoidCallback onStartPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: onReset,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(18),
            shape: const CircleBorder(),
            side: const BorderSide(color: RivioColors.border),
          ),
          child: const Icon(Icons.refresh, color: RivioColors.textSecondary),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: onStartPause,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(24),
            shape: const CircleBorder(),
          ),
          child: Icon(
            isRunning ? Icons.pause : Icons.play_arrow,
            size: 32,
          ),
        ),
      ],
    );
  }
}
