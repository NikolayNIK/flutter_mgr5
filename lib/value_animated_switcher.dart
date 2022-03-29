import 'package:flutter/widgets.dart';

class ValueAnimatedSwitcher<T> extends AnimatedSwitcher {
  ValueAnimatedSwitcher({
    Key? key,
    T? value,
    required Widget? child,
    required Duration duration,
    Duration? reverseDuration,
    Curve switchInCurve = Curves.linear,
    Curve switchOutCurve = Curves.linear,
    AnimatedSwitcherTransitionBuilder transitionBuilder =
        AnimatedSwitcher.defaultTransitionBuilder,
    AnimatedSwitcherLayoutBuilder layoutBuilder =
        AnimatedSwitcher.defaultLayoutBuilder,
  }) : super(
          key: key,
          child: child == null
              ? null
              : KeyedSubtree(
                  key: ValueKey<T?>(value),
                  child: child,
                ),
          duration: duration,
          reverseDuration: reverseDuration,
          switchInCurve: switchInCurve,
          switchOutCurve: switchOutCurve,
          transitionBuilder: transitionBuilder,
          layoutBuilder: layoutBuilder,
        );
}
