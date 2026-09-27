import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../database/database.dart';

class RadarChart extends StatelessWidget {
  const RadarChart({super.key, required this.efforts});

  final List<SubjectEffort> efforts;

  @override
  Widget build(BuildContext context) {
    final ranked = efforts.where((effort) => effort.effortScore > 0).toList()
      ..sort((a, b) => b.effortScore.compareTo(a.effortScore));
    final visible = ranked.take(5).toList();
    if (visible.isEmpty) {
      return const SizedBox(
        height: 210,
        child: Center(
          child: Text(
            'Create flashcards and review a deck to see subject effort here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: RivioColors.secondaryText),
          ),
        ),
      );
    }

    final maxScore = visible.first.effortScore;
    return Column(
      children: [
        SizedBox(
          height: 270,
          child: CustomPaint(
            painter: _RadarPainter(visible, maxScore),
            child: const SizedBox.expand(),
          ),
        ),
        const Divider(height: 20),
        ...visible.map(
          (effort) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    effort.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${effort.cardsCreated} made',
                  style: const TextStyle(
                    color: RivioColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${effort.cardsReviewed} reviewed',
                  style: const TextStyle(
                    color: RivioColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Effort score = cards made + 2 × cards reviewed',
            style: TextStyle(color: RivioColors.secondaryText, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.efforts, this.maxScore);

  final List<SubjectEffort> efforts;
  final int maxScore;

  @override
  void paint(Canvas canvas, Size size) {
    final sides = math.max(3, efforts.length);
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final radius = math.min(size.width / 2 - 64, size.height / 2 - 38);
    if (radius <= 0) return;
    final startAngle = -math.pi / 2;

    Path polygon(double scale) {
      final path = Path();
      for (var index = 0; index < sides; index++) {
        final angle = startAngle + 2 * math.pi * index / sides;
        final point =
            center + Offset(math.cos(angle), math.sin(angle)) * radius * scale;
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path..close();
    }

    final gridPaint = Paint()
      ..color = RivioColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawPath(polygon(ring / 4), gridPaint);
    }
    for (var index = 0; index < sides; index++) {
      final angle = startAngle + 2 * math.pi * index / sides;
      canvas.drawLine(
        center,
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        gridPaint,
      );
    }

    final data = Path();
    for (var index = 0; index < sides; index++) {
      final angle = startAngle + 2 * math.pi * index / sides;
      final value = index < efforts.length
          ? efforts[index].effortScore / maxScore
          : 0.04;
      final point =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              radius *
              math.max(0.05, value);
      if (index == 0) {
        data.moveTo(point.dx, point.dy);
      } else {
        data.lineTo(point.dx, point.dy);
      }
      final label = index < efforts.length
          ? '${efforts[index].subject}\n${efforts[index].effortScore} pts'
          : '';
      if (label.isNotEmpty) {
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: RivioColors.text,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: 90);
        final labelPoint =
            center + Offset(math.cos(angle), math.sin(angle)) * (radius + 20);
        text.paint(
          canvas,
          Offset(
            labelPoint.dx - text.width / 2,
            labelPoint.dy - text.height / 2,
          ),
        );
      }
    }
    data.close();
    canvas.drawPath(
      data,
      Paint()
        ..color = RivioColors.green.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      data,
      Paint()
        ..color = RivioColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    for (var index = 0; index < sides; index++) {
      final angle = startAngle + 2 * math.pi * index / sides;
      final value = index < efforts.length
          ? efforts[index].effortScore / maxScore
          : 0.04;
      final point =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              radius *
              math.max(0.05, value);
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = RivioColors.green
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.efforts != efforts || oldDelegate.maxScore != maxScore;
}
