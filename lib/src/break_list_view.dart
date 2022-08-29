import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

@immutable
class BreakListItemData {
  final Widget middle;
  final Widget? left, right;

  const BreakListItemData({this.left, required this.middle, this.right});
}

typedef BreakItemBuilder = BreakListItemData Function(
    BuildContext context, int index);

class BreakListItem extends StatelessWidget {
  final BreakListItemData data;
  final ViewportOffset offset;
  final double leftSize, middleSize, rightSize;
  final double? extent;

  const BreakListItem({
    Key? key,
    required this.data,
    required this.offset,
    required this.leftSize,
    required this.middleSize,
    required this.rightSize,
    required this.extent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final content = constraints.maxWidth > leftSize + middleSize + rightSize
            ? data.middle
            : SizedBox(
                width: middleSize,
                child: Viewport(
                  axisDirection: AxisDirection.right,
                  offset: offset,
                  slivers: [
                    SliverToBoxAdapter(
                        child: SizedBox(
                      width: middleSize,
                      height: extent,
                      child: data.middle,
                    ))
                  ],
                ),
              );

        return Row(children: [
          if (data.left != null) SizedBox(width: leftSize, child: data.left!),
          Expanded(
            child: data.left == null && data.right == null
                ? content
                : Stack(
                    children: [content],
                  ),
          ),
          if (data.right != null)
            SizedBox(width: rightSize, child: data.right!),
        ]);
      });
}

class BreakListView extends StatefulWidget {
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final Widget? prototypeItem;
  final int? itemCount;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  final BreakItemBuilder itemBuilder;
  final double leftSize, middleSize, rightSize;

  const BreakListView.builder({
    Key? key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    this.prototypeItem,
    this.itemCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    required this.itemBuilder,
    required this.leftSize,
    required this.middleSize,
    required this.rightSize,
  }) : super(key: key);

  @override
  State<BreakListView> createState() => _BreakListViewState();
}

class _BreakListViewState extends State<BreakListView> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: Offset(widget.leftSize, 0),
        child: Scrollbar(
          controller: _controller,
          child: Scrollable(
            controller: _controller,
            axisDirection: AxisDirection.right,
            viewportBuilder: (BuildContext context, ViewportOffset position) =>
                Transform.translate(
              offset: Offset(-widget.leftSize, 0),
              child: ListView.builder(
                scrollDirection: widget.scrollDirection,
                reverse: widget.reverse,
                controller: widget.controller,
                primary: widget.primary,
                physics: widget.physics,
                shrinkWrap: widget.shrinkWrap,
                padding: widget.padding,
                itemExtent: widget.itemExtent,
                prototypeItem: widget.prototypeItem,
                itemCount: widget.itemCount,
                addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
                addRepaintBoundaries: widget.addRepaintBoundaries,
                addSemanticIndexes: widget.addSemanticIndexes,
                cacheExtent: widget.cacheExtent,
                semanticChildCount: widget.semanticChildCount,
                dragStartBehavior: widget.dragStartBehavior,
                keyboardDismissBehavior: widget.keyboardDismissBehavior,
                restorationId: widget.restorationId,
                clipBehavior: widget.clipBehavior,
                itemBuilder: (context, index) => BreakListItem(
                  data: widget.itemBuilder(context, index),
                  offset: position,
                  leftSize: widget.leftSize,
                  middleSize: widget.middleSize,
                  rightSize: widget.rightSize,
                  extent: widget.itemExtent,
                ),
              ),
            ),
          ),
        ),
      );
}
