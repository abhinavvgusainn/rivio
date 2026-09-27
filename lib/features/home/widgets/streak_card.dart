import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Highlights the current study streak. Deliberately the most
/// prominent card on Home — streaks are the habit-forming signal.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: RivioColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: RivioColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: RivioColors.textPrimary,
                  ),
                ),
                Text(
                  streakDays == 1 ? 'day streak' : 'day streak',
                  style: const TextStyle(
                    color: RivioColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
