import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Shows how study time is distributed across subjects.
/// [distribution] maps a subject label to a 0-100 relative score;
/// callers are responsible for normalizing raw minutes into that range.
class StudyRadarChart extends StatelessWidget {
  const StudyRadarChart({super.key, required this.distribution});

  final Map<String, double> distribution;

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Study a few subjects to see your distribution',
            style: TextStyle(color: RivioColors.textSecondary),
          ),
        ),
      );
    }

    final labels = distribution.keys.toList();
    final values = distribution.values.toList();

    return SizedBox(
      height: 220,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          gridBorderData: const BorderSide(color: RivioColors.border),
          radarBorderData: const BorderSide(color: RivioColors.border),
          getTitle: (index, angle) => RadarChartTitle(
            text: labels[index],
            angle: 0,
          ),
          titleTextStyle: const TextStyle(
            color: RivioColors.textSecondary,
            fontSize: 11,
          ),
          dataSets: [
            RadarDataSet(
              fillColor: RivioColors.primary.withValues(alpha: 0.25),
              borderColor: RivioColors.primary,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
