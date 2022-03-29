import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Combines [ValueListenableBuilder] and [AnimatedSwitcher]
class ValueListenableAnimatedSwitcherBuilder<T> extends StatelessWidget {
  final Duration duration;
  final ValueListenable<T> valueListenable;
  final ValueWidgetBuilder<T> builder;
  final Widget? child;
  final Duration? reverseDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  const ValueListenableAnimatedSwitcherBuilder({
    Key? key,
    required this.duration,
    required this.valueListenable,
    required this.builder,
    this.child,
    this.reverseDuration,
    this.switchInCurve = Curves.linear,
    this.switchOutCurve = Curves.linear,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<T>(
        valueListenable: valueListenable,
        builder: (context, value, child) => AnimatedSwitcher(
          duration: duration,
          layoutBuilder: layoutBuilder,
          switchInCurve: switchInCurve,
          switchOutCurve: switchOutCurve,
          reverseDuration: reverseDuration,
          transitionBuilder: transitionBuilder,
          child: KeyedSubtree(
            key: ValueKey<T>(value),
            child: builder(context, value, this.child),
          ),
        ),
      );
}
