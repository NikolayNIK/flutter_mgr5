import 'package:flutter/widgets.dart';

Widget _clipContainerBuilder(BuildContext context, Widget? child) =>
    ClipRect(child: child);

class AnimatedRectReveal extends StatelessWidget {
  final Widget child;
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
    required this.child,
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
                      offset: (contentOffset + Offset(leftDiff, topDiff)) *
                          valueInverted,
                      child: RepaintBoundary(
                        child: child,
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
