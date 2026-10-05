import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:habitrak/core/theme/app_theme.dart';

/// A high-performance, ultra-low-memory organic river flow background.
///
/// Uses pure vector math and hardware-accelerated canvas bezier paths
/// without loading any images, videos, or heavy asset runtimes into memory.
class RiverFlowBackground extends StatefulWidget {
  final Widget? child;

  const RiverFlowBackground({super.key, this.child});

  @override
  State<RiverFlowBackground> createState() => _RiverFlowBackgroundState();
}

class _RiverFlowBackgroundState extends State<RiverFlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A slow, calming 16-second loop provides a serene natural river ambiance.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: CustomPaint(
        painter: RiverFlowPainter(animation: _controller, isDark: isDark),
        child: widget.child,
      ),
    );
  }
}

class RiverFlowPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  // Cached paint objects to eliminate per-frame allocations and garbage collection
  final Paint _basePaint = Paint();
  final Paint _streamPaint1 = Paint()..style = PaintingStyle.fill;
  final Paint _streamPaint2 = Paint()..style = PaintingStyle.fill;
  final Paint _contourPaint1 = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _contourPaint2 = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

  final Path _path1 = Path();
  final Path _path2 = Path();
  final Path _contourPath1 = Path();
  final Path _contourPath2 = Path();

  RiverFlowPainter({required this.animation, required this.isDark})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final progress = animation.value;
    final t = progress * 2 * math.pi;

    // 1. Draw solid foundation color preserving exact app theme
    _basePaint.color = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _basePaint);

    // Color definitions respecting the Stitch Design theme colors (sage greens & soft neutrals)
    final Color streamColor1Start;
    final Color streamColor1End;
    final Color streamColor2Start;
    final Color streamColor2End;
    final Color contourColor1;
    final Color contourColor2;
    final Color particleColor;

    if (isDark) {
      streamColor1Start = const Color(0xff182219).withValues(alpha: 0.55);
      streamColor1End = const Color(0xff131c14).withValues(alpha: 0.35);
      streamColor2Start = const Color(0xff1b261d).withValues(alpha: 0.45);
      streamColor2End = const Color(0xff141e15).withValues(alpha: 0.25);
      contourColor1 = AppColors.darkPrimary.withValues(alpha: 0.08);
      contourColor2 = AppColors.darkSecondary.withValues(alpha: 0.06);
      particleColor = AppColors.darkPrimary.withValues(alpha: 0.12);
    } else {
      streamColor1Start = const Color(0xffe8f3ea).withValues(alpha: 0.65);
      streamColor1End = const Color(0xfff0f7f1).withValues(alpha: 0.40);
      streamColor2Start = const Color(0xffe2efe4).withValues(alpha: 0.50);
      streamColor2End = const Color(0xffedf6ef).withValues(alpha: 0.30);
      contourColor1 = AppColors.lightPrimary.withValues(alpha: 0.12);
      contourColor2 = AppColors.lightSecondary.withValues(alpha: 0.08);
      particleColor = AppColors.lightPrimary.withValues(alpha: 0.18);
    }

    // 2. Primary Wide River Current (flowing diagonally from top-left to bottom-right)
    _path1.reset();
    _streamPaint1.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [streamColor1Start, streamColor1End],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    const stepY = 28.0;
    final steps = (h / stepY).ceil() + 1;

    // Left bank of stream 1
    _path1.moveTo(-w * 0.1, -20);
    for (int i = 0; i <= steps; i++) {
      final y = i * stepY;
      final normY = y / h;
      // Fluid sinusoidal meandering math
      final wave1 = math.sin((normY * 2.2 * math.pi) - t);
      final wave2 = math.cos((normY * 4.0 * math.pi) + (t * 0.7));
      final centerX = (w * 0.45) + (w * 0.22 * wave1) + (w * 0.08 * wave2);
      final halfWidth =
          (w * 0.32) +
          (w * 0.06 * math.sin((normY * 3.0 * math.pi) + (t * 0.5)));
      final x = (centerX - halfWidth).clamp(-w * 0.2, w * 1.2);
      if (i == 0) {
        _path1.moveTo(x, y);
      } else {
        _path1.lineTo(x, y);
      }
    }

    // Right bank of stream 1
    for (int i = steps; i >= 0; i--) {
      final y = i * stepY;
      final normY = y / h;
      final wave1 = math.sin((normY * 2.2 * math.pi) - t);
      final wave2 = math.cos((normY * 4.0 * math.pi) + (t * 0.7));
      final centerX = (w * 0.45) + (w * 0.22 * wave1) + (w * 0.08 * wave2);
      final halfWidth =
          (w * 0.32) +
          (w * 0.06 * math.sin((normY * 3.0 * math.pi) + (t * 0.5)));
      final x = (centerX + halfWidth).clamp(-w * 0.2, w * 1.2);
      _path1.lineTo(x, y);
    }
    _path1.close();
    canvas.drawPath(_path1, _streamPaint1);

    // 3. Secondary Intersecting Current (flowing with harmonic phase difference)
    _path2.reset();
    _streamPaint2.shader = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [streamColor2Start, streamColor2End],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    for (int i = 0; i <= steps; i++) {
      final y = i * stepY;
      final normY = y / h;
      final waveA = math.cos((normY * 2.8 * math.pi) + (t * 1.3) + 1.2);
      final waveB = math.sin((normY * 3.6 * math.pi) - (t * 0.6));
      final centerX = (w * 0.60) + (w * 0.25 * waveA) + (w * 0.06 * waveB);
      final halfWidth =
          (w * 0.24) + (w * 0.05 * math.cos((normY * 2.0 * math.pi) - t));
      final x = (centerX - halfWidth).clamp(-w * 0.2, w * 1.2);
      if (i == 0) {
        _path2.moveTo(x, y);
      } else {
        _path2.lineTo(x, y);
      }
    }
    for (int i = steps; i >= 0; i--) {
      final y = i * stepY;
      final normY = y / h;
      final waveA = math.cos((normY * 2.8 * math.pi) + (t * 1.3) + 1.2);
      final waveB = math.sin((normY * 3.6 * math.pi) - (t * 0.6));
      final centerX = (w * 0.60) + (w * 0.25 * waveA) + (w * 0.06 * waveB);
      final halfWidth =
          (w * 0.24) + (w * 0.05 * math.cos((normY * 2.0 * math.pi) - t));
      final x = (centerX + halfWidth).clamp(-w * 0.2, w * 1.2);
      _path2.lineTo(x, y);
    }
    _path2.close();
    canvas.drawPath(_path2, _streamPaint2);

    // 4. Subtle Flow Contours (gentle river ripple lines)
    _contourPath1.reset();
    _contourPaint1
      ..color = contourColor1
      ..strokeWidth = 1.6;

    for (int i = 0; i <= steps; i++) {
      final y = i * stepY;
      final normY = y / h;
      final wave = math.sin((normY * 2.4 * math.pi) - t + 0.5);
      final x = (w * 0.42) + (w * 0.24 * wave);
      if (i == 0) {
        _contourPath1.moveTo(x, y);
      } else {
        _contourPath1.lineTo(x, y);
      }
    }
    canvas.drawPath(_contourPath1, _contourPaint1);

    _contourPath2.reset();
    _contourPaint2
      ..color = contourColor2
      ..strokeWidth = 1.2;

    for (int i = 0; i <= steps; i++) {
      final y = i * stepY;
      final normY = y / h;
      final wave = math.cos((normY * 2.6 * math.pi) + (t * 1.1) + 1.8);
      final x = (w * 0.68) + (w * 0.20 * wave);
      if (i == 0) {
        _contourPath2.moveTo(x, y);
      } else {
        _contourPath2.lineTo(x, y);
      }
    }
    canvas.drawPath(_contourPath2, _contourPaint2);

    // 5. Calm Drifting Droplets / River Particles (7 lightweight particles looping downstream)
    _particlePaint.color = particleColor;
    const particleCount = 7;
    for (int i = 0; i < particleCount; i++) {
      final seed = (i * 0.1428); // Evenly spaced initial phases
      final particleProgress = (progress + seed) % 1.0;
      final py = particleProgress * (h + 40) - 20;
      final normY = (py / h).clamp(0.0, 1.0);
      final wave = math.sin((normY * 2.2 * math.pi) - t + (i * 0.8));
      final px =
          (w * 0.46) + (w * 0.22 * wave) + (math.sin(i * 1.7) * (w * 0.12));
      final radius = 1.6 + (math.sin(t + i) * 0.6);

      // Gentle fade-in and fade-out at screen edges
      final edgeAlpha = math.sin(particleProgress * math.pi);
      _particlePaint.color = particleColor.withValues(
        alpha: particleColor.a * edgeAlpha,
      );

      canvas.drawCircle(Offset(px, py), radius, _particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant RiverFlowPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.isDark != isDark;
  }
}
