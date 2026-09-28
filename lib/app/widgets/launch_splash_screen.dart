import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LaunchSplashScreen extends StatelessWidget {
  const LaunchSplashScreen({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF082E20),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final radius = math.min(width * .302, height * .145).toDouble();
          final centerX = width / 2;
          final centerY = height * .467;

          return Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _BackdropPainter()),
              ),
              Positioned(
                left: centerX - radius,
                top: centerY - radius,
                width: radius * 2,
                height: radius * 2,
                child: const CustomPaint(painter: _StudyMarkPainter()),
              ),
              Positioned(
                top: centerY + radius * 1.45,
                left: 0,
                right: 0,
                height: 56,
                child: const Center(
                  child: Text(
                    'Rivio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.8,
                      shadows: [
                        Shadow(
                          color: Color(0x55001C12),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF06291D),
            Color(0xFF0A3928),
            Color(0xFF10563B),
            Color(0xFF167A55),
            Color(0xFF19825D),
          ],
          stops: [0, .28, .53, .78, 1],
        ).createShader(bounds),
    );

    final glowCenter = Offset(size.width * .5, size.height * .51);
    final glowRadius = size.height * .48;
    final glowBounds = Rect.fromCircle(center: glowCenter, radius: glowRadius);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0x7243A878), Color(0x00378F68)],
          stops: const [0, 1],
        ).createShader(glowBounds),
    );

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.05),
          radius: 1.03,
          colors: const [Color(0x00051D14), Color(0x3D001B11)],
          stops: const [.48, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => false;
}

class _StudyMarkPainter extends CustomPainter {
  const _StudyMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height).toDouble() * .49;

    _drawGlow(canvas, center, radius * 1.15);
    _drawGeometry(canvas, center, radius);
    _drawOrbit(canvas, center, radius);
    _drawBookAndProgress(canvas, center, radius);
  }

  void _drawGlow(Canvas canvas, Offset center, double radius) {
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x5C66D9A6), Color(0x001B9B6B)],
          stops: [0, 1],
        ).createShader(bounds),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * .62),
        width: radius * 1.5,
        height: radius * .32,
      ),
      Paint()
        ..color = const Color(0x333DF0AE)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  void _drawGeometry(Canvas canvas, Offset center, double radius) {
    final outerHex = _hexagon(center, radius * .83);
    _drawDashedPath(
      canvas,
      outerHex,
      Paint()
        ..color = const Color(0x456ED3A3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15,
      dashLength: 3.2,
      gapLength: 4.6,
    );

    final innerRadius = radius * .53;
    final innerHex = _hexagon(center, innerRadius);
    canvas.drawPath(
      innerHex,
      Paint()
        ..color = const Color(0x4269D4A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15,
    );

    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + index * math.pi / 3;
      final outerPoint = _pointOnCircle(center, radius * .83, angle);
      final innerPoint = _pointOnCircle(center, innerRadius, angle);
      canvas.drawLine(
        innerPoint,
        outerPoint,
        Paint()
          ..color = const Color(0x3267D4A0)
          ..strokeWidth = 1,
      );
    }

    canvas.drawLine(
      Offset(center.dx, center.dy - innerRadius),
      Offset(center.dx, center.dy + innerRadius),
      Paint()
        ..color = const Color(0x2C67D4A0)
        ..strokeWidth = 1,
    );
  }

  void _drawOrbit(Canvas canvas, Offset center, double radius) {
    final orbitRadius = radius * .985;
    final orbitBounds = Rect.fromCircle(center: center, radius: orbitRadius);
    final trackPaint = Paint()
      ..color = const Color(0x3572D9A9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .038
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, orbitRadius, trackPaint);

    final upperArc = Paint()
      ..color = const Color(0xFF22C996)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .038
      ..strokeCap = StrokeCap.round;
    final upperGlow = Paint()
      ..color = const Color(0x8822C996)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final lowerArc = Paint()
      ..color = const Color(0xFFAEF7D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .038
      ..strokeCap = StrokeCap.round;
    final lowerGlow = Paint()
      ..color = const Color(0x88A4F0C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(orbitBounds, -math.pi / 2, math.pi / 2, false, upperGlow);
    canvas.drawArc(orbitBounds, math.pi / 2, math.pi / 2, false, lowerGlow);
    canvas.drawArc(orbitBounds, -math.pi / 2, math.pi / 2, false, upperArc);
    canvas.drawArc(orbitBounds, math.pi / 2, math.pi / 2, false, lowerArc);

    _drawOrbitDot(
      canvas,
      _pointOnCircle(center, orbitRadius, -math.pi / 2),
      radius,
      const Color(0xFF5DE0B1),
    );
    _drawOrbitDot(
      canvas,
      _pointOnCircle(center, orbitRadius, 0),
      radius,
      const Color(0xFF3DD6A2),
    );
    _drawOrbitDot(
      canvas,
      _pointOnCircle(center, orbitRadius, math.pi),
      radius,
      const Color(0xFFA3F3CE),
    );
  }

  void _drawOrbitDot(Canvas canvas, Offset point, double radius, Color color) {
    canvas.drawCircle(
      point,
      radius * .05,
      Paint()
        ..color = color.withAlpha(100)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(point, radius * .024, Paint()..color = color);
  }

  void _drawBookAndProgress(Canvas canvas, Offset center, double radius) {
    final pageTop = center.dy - radius * .075;
    final pageBottom = center.dy + radius * .39;
    final halfBookWidth = radius * .45;
    final bookCenterX = center.dx;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bookCenterX, pageBottom - radius * .005),
        width: halfBookWidth * 1.85,
        height: radius * .23,
      ),
      Paint()
        ..color = const Color(0x5C001F15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final pageGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC5FFE6), Color(0xFF70DDB3)],
    );
    final leftPage = Path()
      ..moveTo(bookCenterX, pageTop + radius * .035)
      ..cubicTo(
        bookCenterX - radius * .19,
        pageTop - radius * .035,
        bookCenterX - radius * .36,
        pageTop - radius * .02,
        bookCenterX - halfBookWidth,
        pageTop + radius * .055,
      )
      ..lineTo(bookCenterX - halfBookWidth, pageBottom - radius * .015)
      ..cubicTo(
        bookCenterX - radius * .31,
        pageBottom - radius * .09,
        bookCenterX - radius * .13,
        pageBottom - radius * .045,
        bookCenterX,
        pageBottom + radius * .015,
      )
      ..close();
    final rightPage = Path()
      ..moveTo(bookCenterX, pageTop + radius * .035)
      ..cubicTo(
        bookCenterX + radius * .19,
        pageTop - radius * .035,
        bookCenterX + radius * .36,
        pageTop - radius * .02,
        bookCenterX + halfBookWidth,
        pageTop + radius * .055,
      )
      ..lineTo(bookCenterX + halfBookWidth, pageBottom - radius * .015)
      ..cubicTo(
        bookCenterX + radius * .31,
        pageBottom - radius * .09,
        bookCenterX + radius * .13,
        pageBottom - radius * .045,
        bookCenterX,
        pageBottom + radius * .015,
      )
      ..close();
    final pageShader = pageGradient.createShader(
      Rect.fromLTRB(
        bookCenterX - halfBookWidth,
        pageTop - radius * .04,
        bookCenterX + halfBookWidth,
        pageBottom + radius * .03,
      ),
    );
    final pagePaint = Paint()..shader = pageShader;
    canvas.drawPath(leftPage, pagePaint);
    canvas.drawPath(rightPage, pagePaint);

    final edgePaint = Paint()
      ..color = const Color(0xFF54C99B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .018
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(leftPage, edgePaint);
    canvas.drawPath(rightPage, edgePaint);
    canvas.drawLine(
      Offset(bookCenterX, pageTop + radius * .04),
      Offset(bookCenterX, pageBottom + radius * .015),
      Paint()
        ..color = const Color(0xFF50C996)
        ..strokeWidth = radius * .018,
    );

    final barWidth = radius * .075;
    final barData = [
      (
        center.dx - radius * .19,
        pageTop - radius * .15,
        radius * .42,
        const Color(0xFFA2F0CC),
      ),
      (center.dx, pageTop - radius * .22, radius * .53, Colors.white),
      (
        center.dx + radius * .19,
        pageTop - radius * .08,
        radius * .35,
        const Color(0xFF82E4B9),
      ),
    ];
    for (final (x, top, height, color) in barData) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, top, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withAlpha(95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }

    final starCenter = Offset(bookCenterX, pageTop - radius * .25);
    canvas.drawPath(
      _sparkle(starCenter, radius * .105, radius * .035),
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      _sparkle(starCenter, radius * .092, radius * .027),
      Paint()..color = Colors.white,
    );

    final baseline = pageBottom + radius * .035;
    canvas.drawLine(
      Offset(bookCenterX - halfBookWidth, baseline),
      Offset(bookCenterX, baseline + radius * .06),
      Paint()
        ..color = const Color(0xFF45B889)
        ..strokeWidth = radius * .018
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(bookCenterX, baseline + radius * .06),
      Offset(bookCenterX + halfBookWidth, baseline),
      Paint()
        ..color = const Color(0xFF45B889)
        ..strokeWidth = radius * .018
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _hexagon(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final point = _pointOnCircle(
        center,
        radius,
        -math.pi / 2 + index * math.pi / 3,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Offset _pointOnCircle(Offset center, double radius, double angle) => Offset(
    center.dx + math.cos(angle) * radius,
    center.dy + math.sin(angle) * radius,
  );

  Path _sparkle(Offset center, double longRadius, double shortRadius) => Path()
    ..moveTo(center.dx, center.dy - longRadius)
    ..quadraticBezierTo(
      center.dx - shortRadius * .3,
      center.dy - shortRadius * .3,
      center.dx - longRadius * .55,
      center.dy,
    )
    ..quadraticBezierTo(
      center.dx - shortRadius * .3,
      center.dy + shortRadius * .3,
      center.dx,
      center.dy + longRadius,
    )
    ..quadraticBezierTo(
      center.dx + shortRadius * .3,
      center.dy + shortRadius * .3,
      center.dx + longRadius * .55,
      center.dy,
    )
    ..quadraticBezierTo(
      center.dx + shortRadius * .3,
      center.dy - shortRadius * .3,
      center.dx,
      center.dy - longRadius,
    )
    ..close();

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StudyMarkPainter oldDelegate) => false;
}
