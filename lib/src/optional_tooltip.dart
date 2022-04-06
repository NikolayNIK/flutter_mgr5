import 'package:flutter/material.dart';

class OptionalTooltip extends StatelessWidget {
  final String? message;
  final InlineSpan? richMessage;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? verticalOffset;
  final bool? preferBelow;
  final bool? excludeFromSemantics;
  final Widget child;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final Duration? waitDuration;
  final Duration? showDuration;
  final TooltipTriggerMode? triggerMode;
  final bool? enableFeedback;

  const OptionalTooltip({
    Key? key,
    this.message,
    this.richMessage,
    this.height,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.waitDuration,
    this.showDuration,
    this.triggerMode,
    this.enableFeedback,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => message == null && richMessage == null
      ? child
      : Tooltip(
          message: message,
          richMessage: richMessage,
          height: height,
          padding: padding,
          margin: margin,
          verticalOffset: verticalOffset,
          preferBelow: preferBelow,
          excludeFromSemantics: excludeFromSemantics,
          child: child,
          decoration: decoration,
          textStyle: textStyle,
          waitDuration: waitDuration,
          showDuration: showDuration,
          triggerMode: triggerMode,
          enableFeedback: enableFeedback,
        );
}
