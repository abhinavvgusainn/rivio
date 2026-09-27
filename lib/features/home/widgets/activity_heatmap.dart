import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../services/statistics_service.dart';

class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.activity,
    required this.streak,
  });

  final Map<String, DailyStudyActivity> activity;
  final int streak;

  int _level(int effort) {
    if (effort <= 0) return 0;
    if (effort < 4) return 1;
    if (effort < 10) return 2;
    if (effort < 20) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final start = currentWeekStart.subtract(const Duration(days: 28));
    final days = List.generate(35, (index) => start.add(Duration(days: index)));
    final formatter = DateFormat('yyyy-MM-dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            _WeekdayLabel('M'),
            _WeekdayLabel('T'),
            _WeekdayLabel('W'),
            _WeekdayLabel('T'),
            _WeekdayLabel('F'),
            _WeekdayLabel('S'),
            _WeekdayLabel('S'),
          ],
        ),
        const SizedBox(height: 7),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final dayActivity =
                activity[formatter.format(day)] ?? const DailyStudyActivity();
            final future = day.isAfter(today);
            final color = future
                ? Colors.transparent
                : RivioColors.heatmap[_level(dayActivity.effort)];
            final todayCell = DateUtils.isSameDay(day, today);
            return Tooltip(
              message: future
                  ? ''
                  : '${DateFormat('EEE, MMM d').format(day)}\n${dayActivity.timerMinutes} min timer · ${dayActivity.reviewMinutes} min review · ${dayActivity.cardsReviewed} cards',
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: todayCell
                        ? RivioColors.green
                        : (future
                              ? RivioColors.border.withValues(alpha: 0.5)
                              : Colors.transparent),
                    width: todayCell ? 2 : 1,
                  ),
                ),
                child: todayCell
                    ? const Center(
                        child: Text(
                          'T',
                          style: TextStyle(
                            color: RivioColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Current streak: $streak ${streak == 1 ? 'day' : 'days'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RivioColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Less',
                  style: TextStyle(
                    color: RivioColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
                ...RivioColors.heatmap.map(
                  (color) => Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const Text(
                  'More',
                  style: TextStyle(
                    color: RivioColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Text(
        label,
        style: const TextStyle(color: RivioColors.secondaryText, fontSize: 10),
      ),
    ),
  );
}
