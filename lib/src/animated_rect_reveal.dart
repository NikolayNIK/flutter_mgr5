import 'package:flutter/widgets.dart';

Widget _clipContainerBuilder(BuildContext context, Widget? child) =>
    ClipRect(child: child);

typedef AnimatedRectRevealWidgetBuilder = Widget Function(
  BuildContext context,
  Offset offset,
  Widget? child,
);

Widget _buildSimpleBody(BuildContext context, Offset offset, Widget? child) =>
    Transform.translate(
      offset: offset,
      child: RepaintBoundary(
        child: child,
      ),
    );

class AnimatedRectReveal extends StatelessWidget {
  final AnimatedRectRevealWidgetBuilder builder;
  final Widget? child;
  final TransitionBuilder containerBuilder;
  final Rect originBox, destinationBox;
  final Animation<double> animation;
  final Offset contentOffset;

  const AnimatedRectReveal({
    super.key,
    required this.animation,
    required this.originBox,
    required this.destinationBox,
    this.contentOffset = Offset.zero,
    this.containerBuilder = _clipContainerBuilder,
    required Widget this.child,
  }) : builder = _buildSimpleBody;

  const AnimatedRectReveal.builder({
    super.key,
    required this.animation,
    required this.originBox,
    required this.destinationBox,
    required this.builder,
    this.contentOffset = Offset.zero,
    this.containerBuilder = _clipContainerBuilder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final leftDiff = destinationBox.left - originBox.left;
    final topDiff = destinationBox.top - originBox.top;
    final widthDiff = destinationBox.width - originBox.width;
    final heightDiff = destinationBox.height - originBox.height;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value;
        final valueInverted = 1 - value;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: originBox.left + leftDiff * value,
              top: originBox.top + topDiff * value,
              width: originBox.width + widthDiff * value,
              height: originBox.height + heightDiff * value,
              child: Opacity(
                opacity: value,
                child: containerBuilder(
                  context,
                  OverflowBox(
                    minWidth: destinationBox.width,
                    maxWidth: destinationBox.width,
                    minHeight: destinationBox.height,
                    maxHeight: destinationBox.height,
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: Offset(leftDiff, topDiff) * valueInverted,
                      child: builder(
                        context,
                        contentOffset * valueInverted,
                        child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
