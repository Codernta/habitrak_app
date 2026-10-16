import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:habitrak/core/theme/app_theme.dart';

/// An animated waveform visualizer displaying undulating audio bars in
/// Habitrak's soothing sage green tones.
class WaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;

  const WaveformVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 18,
    this.height = 32,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final secondaryColor = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.lightPrimaryContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.barCount, (index) {
              final phase = (index / widget.barCount) * 2 * math.pi;
              final t = _controller.value * 2 * math.pi;
              final wave = widget.isPlaying
                  ? (math.sin(t + phase) * 0.4 +
                        math.sin(2 * t + phase * 1.5) * 0.2 +
                        0.5)
                  : 0.15 + (math.sin(index * 0.8) * 0.08);

              final barHeight = (wave.clamp(0.12, 1.0) * widget.height);

              return Container(
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [secondaryColor, primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
