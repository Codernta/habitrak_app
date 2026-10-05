import 'package:flutter/material.dart';
import 'app_animations.dart';

/// Staggered fade + slide-up entrance for list items and cards.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.slideAxis = Axis.vertical,
    this.play = true,
  });

  final Widget child;
  final int index;
  final Duration? delay;
  final Axis slideAxis;
  final bool play;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: AppAnimations.spring),
    );
    _offset = Tween<Offset>(
      begin: widget.slideAxis == Axis.vertical
          ? const Offset(0, 0.12)
          : const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.85, curve: AppAnimations.bounce),
    ));
    _scale = Tween<double>(begin: 0.94, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.8, curve: AppAnimations.spring),
    ));
    if (widget.play) {
      _schedulePlay();
    }
  }

  void _schedulePlay() {
    final delay = widget.delay ??
        Duration(
          milliseconds: (widget.index * AppAnimations.staggerStepMs).round(),
        );
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(StaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _schedulePlay();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: AppAnimations.clampOpacity(_opacity.value),
          child: Transform.translate(
            offset: Offset(
              _offset.value.dx * AppAnimations.slideDistance,
              _offset.value.dy * AppAnimations.slideDistance,
            ),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
