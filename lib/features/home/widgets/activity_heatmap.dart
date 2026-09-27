import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';

/// GitHub-style contribution heatmap: one column per week, one cell
/// per day, colored by minutes studied that day.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.minutesByDay,
    this.weeksToShow = 18,
  });

  /// 'yyyy-MM-dd' -> minutes studied that day.
  final Map<String, int> minutesByDay;
  final int weeksToShow;

  static const _cellSize = 14.0;
  static const _cellGap = 4.0;

  int _levelFor(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes < 15) return 1;
    if (minutes < 30) return 2;
    if (minutes < 60) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd');
    final today = DateUtils.dateOnly(DateTime.now());
    // Align the grid so the last column ends on the current week.
    final daysBack = weeksToShow * 7 + today.weekday - 1;
    final start = today.subtract(Duration(days: daysBack));

    final weeks = <List<DateTime?>>[];
    var cursor = start.subtract(Duration(days: start.weekday - 1));
    for (var w = 0; w < weeksToShow + 1; w++) {
      final week = <DateTime?>[];
      for (var d = 0; d < 7; d++) {
        final day = cursor.add(Duration(days: d));
        week.add(day.isAfter(today) ? null : day);
      }
      weeks.add(week);
      cursor = cursor.add(const Duration(days: 7));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.only(right: _cellGap),
            child: Column(
              children: week.map((day) {
                final minutes =
                    day == null ? 0 : (minutesByDay[formatter.format(day)] ?? 0);
                final color = day == null
                    ? Colors.transparent
                    : RivioColors.heatmapLevels[_levelFor(minutes)];
                return Padding(
                  padding: const EdgeInsets.only(bottom: _cellGap),
                  child: Container(
                    width: _cellSize,
                    height: _cellSize,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
