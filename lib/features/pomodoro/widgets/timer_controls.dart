import 'package:flutter/material.dart';

import '../../../app/theme.dart';

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
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 62,
        child: FilledButton.icon(
          onPressed: onStartPause,
          icon: Icon(
            isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 25,
          ),
          label: Text(
            isRunning ? 'Pause Session' : 'Start Session',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: 7),
      Row(
        children: [
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: RivioColors.secondaryText,
            ),
          ),
          const Spacer(),
        ],
      ),
    ],
  );
}
