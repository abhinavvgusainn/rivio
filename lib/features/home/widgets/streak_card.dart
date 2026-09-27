import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streakDays});
  final int streakDays;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keep your momentum'),
        content: Text(
          streakDays == 0
              ? 'Finish a focus session or flashcard review today to start your streak.'
              : 'You have studied for $streakDays ${streakDays == 1 ? 'day' : 'days'} in a row. A completed focus session or deck review keeps it going.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    ),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF8E9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 27)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$streakDays day streak',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F1EB),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: RivioColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Keep your momentum going',
                    style: TextStyle(
                      color: RivioColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: RivioColors.green),
          ],
        ),
      ),
    ),
  );
}
