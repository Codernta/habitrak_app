import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:habitrak/core/theme/app_theme.dart';

/// A theme-aligned offline animation widget powered by Lottie with an organic
/// vector fallback painter tailored to Habitrak's aesthetic.
class OfflineLottieWidget extends StatefulWidget {
  final double width;
  final double height;
  final bool animate;

  const OfflineLottieWidget({
    super.key,
    this.width = 200,
    this.height = 200,
    this.animate = true,
  });

  @override
  State<OfflineLottieWidget> createState() => _OfflineLottieWidgetState();
}

class _OfflineLottieWidgetState extends State<OfflineLottieWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fallbackController;

  @override
  void initState() {
    super.initState();
    _fallbackController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.animate) {
      _fallbackController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Lottie.asset(
        'assets/lottie/offline_habitrak.json',
        width: widget.width,
        height: widget.height,
        animate: widget.animate,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _HabitrakOfflineFallbackPainter(
              animation: _fallbackController,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          );
        },
      ),
    );
  }
}

class _HabitrakOfflineFallbackPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  _HabitrakOfflineFallbackPainter({
    required this.animation,
    required this.isDark,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final containerColor = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.lightPrimaryContainer;
    final animVal = animation.value;

    // 1. Concentric ripples
    final rippleRadius = (size.width * 0.38) * (0.85 + animVal * 0.15);
    final ripplePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15 * (1.0 - animVal * 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, rippleRadius, ripplePaint);

    // 2. Central soft disc
    final discRadius = size.width * 0.28;
    final discPaint = Paint()
      ..color = containerColor.withValues(alpha: isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, discRadius, discPaint);

    // 3. Wifi arcs
    final arcPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    // Outer Arc
    final outerRect = Rect.fromCircle(
      center: center.translate(0, 10),
      radius: discRadius * 0.7,
    );
    canvas.drawArc(outerRect, -math.pi * 0.75, math.pi * 0.5, false, arcPaint);

    // Inner Arc
    final innerRect = Rect.fromCircle(
      center: center.translate(0, 10),
      radius: discRadius * 0.45,
    );
    canvas.drawArc(innerRect, -math.pi * 0.75, math.pi * 0.5, false, arcPaint);

    // Bottom Dot
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(0, 10), 4.5, dotPaint);

    // 4. Subtle disconnect slash
    final slashPaint = Paint()
      ..color = isDark ? AppColors.darkTertiary : const Color(0xffd9777f)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    final slashLen = discRadius * 0.75;
    canvas.drawLine(
      center.translate(-slashLen * 0.5, -slashLen * 0.5),
      center.translate(slashLen * 0.5, slashLen * 0.5),
      slashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HabitrakOfflineFallbackPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
