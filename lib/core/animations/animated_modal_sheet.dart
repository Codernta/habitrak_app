import 'package:flutter/material.dart';
import 'app_animations.dart';

Future<T?> showAnimatedModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (context) => _AnimatedSheetWrapper(child: builder(context)),
  );
}

class _AnimatedSheetWrapper extends StatefulWidget {
  const _AnimatedSheetWrapper({required this.child});

  final Widget child;

  @override
  State<_AnimatedSheetWrapper> createState() => _AnimatedSheetWrapperState();
}

class _AnimatedSheetWrapperState extends State<_AnimatedSheetWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _slide = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.bounce),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.spring),
    );
    _controller.forward();
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
        return Transform.translate(
          offset: Offset(0, _slide.value * 60),
          child: Opacity(
            opacity: AppAnimations.clampOpacity(_fade.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
