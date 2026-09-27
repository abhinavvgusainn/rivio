import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Circular countdown ring with the remaining time in the center.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({
    super.key,
    required this.remaining,
    required this.total,
  });

  final Duration remaining;
  final Duration total;

  String get _label {
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = total.inSeconds == 0
        ? 0.0
        : 1 - (remaining.inSeconds / total.inSeconds);

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: RivioColors.border,
              valueColor: const AlwaysStoppedAnimation(RivioColors.primary),
            ),
          ),
          Text(
            _label,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: RivioColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
