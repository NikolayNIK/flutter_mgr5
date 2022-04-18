import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/iterator_extensions.dart';
import 'package:flutter_mgr5/listenable_builder.dart';
import 'package:flutter_mgr5/src/list/mgr_list_controller.dart';
import 'package:flutter_mgr5/src/list/mgr_list_model.dart';
import 'package:flutter_mgr5/src/optional_tooltip.dart';
import 'package:flutter_mgr5/value_animated_switcher.dart';
import 'package:shimmer/shimmer.dart';

class _Col {
  final MgrListCol col;
  final double width;

  _Col({
    required this.col,
    required this.width,
  });
}

typedef _RowBuilder = Widget Function(
    Widget checkbox, Widget Function(_Col col));

class MgrList extends StatefulWidget {
  final MgrListModel model;
  final MgrListController controller;

  const MgrList({
    Key? key,
    required this.model,
    required this.controller,
  }) : super(key: key);

  @override
  State<MgrList> createState() => _MgrListState();
}

class _MgrListState extends State<MgrList> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  double _baseRowHeightScale = 1.0;
  double? _baseVerticalScrollPositionPixels;
  double _baseLocalPointY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTitle(context),
        _buildToolbar(),
        Expanded(child: _buildTable()),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) => InkWell(
        onTap: () => widget.controller.items.clear(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: max(
              8.0,
              8.0 + 4.0 * Theme.of(context).visualDensity.vertical,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.model.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => widget.controller.items.clear(),
                  icon: Icon(Icons.refresh)),
            ],
          ),
        ),
      );

  Widget _buildToolbar() => Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ListenableBuilder(
            listenable: widget.controller.selection,
            builder: (context) => Row(
              children: [
                for (final toolgrp in widget.model.toolbar) ...[
                  const SizedBox(width: 8.0),
                  for (final toolbtn in toolgrp)
                    OptionalTooltip(
                      message: toolbtn.hint,
                      child: Builder(builder: (context) {
                        final enabled = toolbtn.selectionType
                            .check(widget.controller.selection.length);
                        return InkResponse(
                          onTap: enabled ? () {} : null,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: ConstrainedBox(
                              key: ValueKey(enabled),
                              constraints: BoxConstraints(
                                  minWidth: 56.0 +
                                      4.0 *
                                          Theme.of(context)
                                              .visualDensity
                                              .horizontal,
                                  minHeight: 56.0 +
                                      4.0 *
                                          Theme.of(context)
                                              .visualDensity
                                              .vertical),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8.0,
                                  bottom: 8.0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      toolbtn.icon,
                                      color: enabled
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(.25),
                                    ),
                                    if (toolbtn.label != null)
                                      Text(
                                        toolbtn.label!,
                                        textAlign: TextAlign.center,
                                        style: (Theme.of(context)
                                                    .textTheme
                                                    .labelMedium ??
                                                TextStyle())
                                            .copyWith(
                                                color: enabled
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(.5)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(width: 24.0),
                ],
              ],
            ),
          ),
        ),
      );

  /// TODO
  static const _MIN_WIDTH = 200.0;
  static const _MIN_WIDTH_RATIO = .5;

  /// TODO
  static const _BREAK_DIVIDER_REVEAL_OFFSET = 8.0;

  Widget _buildTable() => GestureDetector(
        onScaleStart: (details) {
          _baseRowHeightScale = widget.controller.rowHeightScale.value;
          _baseVerticalScrollPositionPixels =
              _verticalScrollController.position.hasPixels
                  ? _verticalScrollController.position.pixels
                  : null;
          _baseLocalPointY = details.localFocalPoint.dy;
        },
        onScaleUpdate: (details) {
          if (details.verticalScale == 1.0) {
            return;
          }

          final value = _baseRowHeightScale * details.verticalScale;
          final clampedValue =
              widget.controller.rowHeightScale.value = max(.5, min(1.0, value));
          final baseOffset = _baseVerticalScrollPositionPixels;
          if (baseOffset != null) {
            _verticalScrollController.position.jumpTo(
              ((baseOffset + _baseLocalPointY) * details.verticalScale -
                      details.localFocalPoint.dy) *
                  (clampedValue / value),
            );
          }
        },
        child: ValueListenableBuilder<double>(
          valueListenable: widget.controller.rowHeightScale,
          builder: (context, rowScale, _) => LayoutBuilder(
            builder: (context, constraints) {
              final coldata = widget.model.coldata;

              final rowHeight = rowScale * 56.0 +
                  8.0 * Theme.of(context).visualDensity.vertical;

              final availableWidth = constraints.maxWidth - 16.0;

              final totalColWidth = coldata
                      .map((e) => e.width)
                      .reduce((value, element) => value + element) +
                  rowHeight;
              final needsBreaks = totalColWidth > availableWidth;

              final Widget body;
              if (needsBreaks) {
                final minWidth =
                    max(_MIN_WIDTH, _MIN_WIDTH_RATIO * availableWidth);

                var alternating = false;
                var leftCount = 2;
                var rightCount = 1;
                late double leftWidth;
                late double rightWidth;
                while (true) {
                  if (leftCount + rightCount + 1 < coldata.length) {
                    if (leftCount == 0 && rightCount == 0) {
                      leftWidth = rowHeight;
                      rightWidth = 0;
                      break;
                    } else {
                      leftWidth = leftCount == 0
                          ? rowHeight
                          : leftCount == 1
                              ? coldata[0].width + rowHeight
                              : coldata
                                      .take(leftCount)
                                      .map((e) => e.width)
                                      .reduce(
                                          (value, element) => value + element) +
                                  rowHeight;

                      rightWidth = rightCount == 0
                          ? 0
                          : rightCount == 1
                              ? coldata[coldata.length - 1].width
                              : coldata
                                  .skip(coldata.length - rightCount)
                                  .map((e) => e.width)
                                  .reduce((value, element) => value + element);
                    }

                    if (availableWidth - leftWidth - rightWidth >= minWidth) {
                      break;
                    }
                  }

                  (alternating = !alternating) ? leftCount-- : rightCount--;
                }

                final middle = List<_Col>.unmodifiable(coldata
                    .skip(leftCount)
                    .take(coldata.length - rightCount - leftCount)
                    .map((col) => _Col(col: col, width: col.width)));
                final left = List<_Col>.unmodifiable(coldata
                    .take(leftCount)
                    .map((col) => _Col(col: col, width: col.width)));
                final right = List<_Col>.unmodifiable(coldata
                    .skip(coldata.length - rightCount)
                    .map((col) => _Col(col: col, width: col.width)));

                final middleInnerWidth = middle
                    .map((e) => e.width)
                    .reduce((value, element) => value + element);

                Widget offsetRowBuilder(ViewportOffset offset, Widget checkbox,
                    Widget builder(_Col col)) {
                  final middleContent =
                      Row(children: List.unmodifiable(middle.map(builder)));

                  final content = SizedBox(
                    height: rowHeight,
                    child: Viewport(
                      axisDirection: AxisDirection.right,
                      offset: offset,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: rightCount == 0
                                ? const EdgeInsets.only(right: 8.0)
                                : EdgeInsets.zero,
                            child: SizedBox(
                              width: middleInnerWidth,
                              height: rowHeight,
                              child: middleContent,
                            ),
                          ),
                        )
                      ],
                    ),
                  );

                  //print('${_horizontalScrollController.position.extentBefore} ${_horizontalScrollController.position.extentAfter}');

                  final bgColor = Theme.of(context).colorScheme.surface;
                  final dividerColor = Theme.of(context).dividerColor;

                  return Padding(
                    padding: rightCount == 0
                        ? const EdgeInsets.only(left: 8.0)
                        : const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                            width: leftWidth,
                            child: Row(children: [
                              SizedBox(
                                width: rowHeight,
                                height: rowHeight,
                                child: checkbox,
                              ),
                              ...left.map(builder),
                            ])),
                        Expanded(
                          child: Stack(
                            children: [
                              content,
                              if (_horizontalScrollController
                                  .position.hasContentDimensions)
                                SizedBox(
                                  height: rowHeight,
                                  child: VerticalDivider(
                                    width: 1.0,
                                    thickness: 1.0,
                                    color: dividerColor.withOpacity(
                                        dividerColor.opacity *
                                            min(
                                                _BREAK_DIVIDER_REVEAL_OFFSET,
                                                _horizontalScrollController
                                                    .position.extentBefore) /
                                            _BREAK_DIVIDER_REVEAL_OFFSET),
                                  ),
                                ),
                              if (_horizontalScrollController
                                      .position.hasContentDimensions &&
                                  rightCount > 0)
                                SizedBox(
                                  height: rowHeight,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: VerticalDivider(
                                      width: 1.0,
                                      thickness: 1.0,
                                      color: dividerColor.withOpacity(dividerColor
                                              .opacity *
                                          ((min(
                                                  _BREAK_DIVIDER_REVEAL_OFFSET,
                                                  _horizontalScrollController
                                                      .position.extentAfter) /
                                              _BREAK_DIVIDER_REVEAL_OFFSET))),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (rightCount > 0)
                          SizedBox(
                              width: rightWidth,
                              child: Row(
                                  children:
                                      List.unmodifiable(right.map(builder)))),
                      ],
                    ),
                  );
                }

                body = Scrollbar(
                  isAlwaysShown: true,
                  controller: _horizontalScrollController,
                  child: Scrollable(
                    controller: _horizontalScrollController,
                    axisDirection: AxisDirection.right,
                    viewportBuilder: (context, position) {
                      _RowBuilder rowBuilder = (checkbox, toWidget) =>
                          offsetRowBuilder(position, checkbox, toWidget);

                      return ListenableBuilder(
                        listenable: _horizontalScrollController,
                        builder: (context) => Column(
                          children: [
                            _buildTableHead(rowHeight, rowBuilder),
                            Divider(
                              height: 2,
                              thickness: 2,
                              indent: 16.0,
                            ),
                            Expanded(
                              child:
                                  NotificationListener<OverscrollNotification>(
                                // Suppress OverscrollNotification events that escape from the inner scrollable
                                onNotification: (notification) => true,
                                child: _buildTableBody(rowHeight, rowBuilder),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              } else {
                final factor = availableWidth / totalColWidth;
                final cols = List<_Col>.unmodifiable(coldata
                    .map((col) => _Col(col: col, width: col.width * factor)));

                _RowBuilder rowBuilder = (checkbox, toWidget) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: rowHeight,
                            height: rowHeight,
                            child: checkbox,
                          ),
                          ...cols.map(toWidget),
                        ],
                      ),
                    );

                body = Column(
                  children: [
                    _buildTableHead(rowHeight, rowBuilder),
                    Divider(
                      height: 2,
                      thickness: 2,
                      indent: 16.0,
                    ),
                    Expanded(
                      child: _buildTableBody(rowHeight, rowBuilder),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(child: body),
                  Divider(
                    height: 2,
                    thickness: 2,
                    indent: 16.0,
                  ),
                  _buildTableFooter(),
                ],
              );
            },
          ),
        ),
      );

  Widget _buildTableHead(double itemHeight, _RowBuilder rowBuilder) =>
      Material(
        color: Colors.transparent,
        child: rowBuilder(
          ListenableBuilder(
              listenable: widget.controller.selection,
              builder: (context) => Checkbox(
                  value: widget.controller.selection.isNotEmpty
                      ? (widget.controller.selection.length ==
                              widget.controller.items.length
                          ? true
                          : null)
                      : false,
                  tristate: true,
                  onChanged: (value) => value ?? false
                      ? widget.controller.selection.addAll(widget
                          .controller.items
                          .map((e) => e?[widget.model.keyField])
                          .whereNotNull())
                      : widget.controller.selection.clear())),
          (col) {
            final text = Text(
              col.col.label ?? '',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.titleSmall,
            );

            return Material(
              color: Colors.transparent,
              child: OptionalTooltip(
                message: col.col.hint,
                child: InkResponse(
                  radius: col.width / 2,
                  onTap: () {},
                  child: SizedBox(
                    width: col.width,
                    height: itemHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: col.col.sorted == null
                            ? text
                            : Row(
                                children: [
                                  Flexible(child: text),
                                  col.col.sorted!.index == 1
                                      ? Icon(col.col.sorted!.ascending
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down)
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Icon(
                                                  col.col.sorted!.ascending
                                                      ? Icons.arrow_drop_up
                                                      : Icons.arrow_drop_down),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Text(
                                                col.col.sorted!.index
                                                    .toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildTableBody(double itemHeight, _RowBuilder rowBuilder) =>
      ListenableBuilder(
        listenable: widget.controller.selection,
        builder: (context) => ListenableBuilder(
          listenable: widget.controller.items,
          builder: (context) => Scrollbar(
            controller: _verticalScrollController,
            isAlwaysShown: true,
            interactive: true,
            trackVisibility: true,
            thickness: 8.0,
            radius: const Radius.circular(8.0),
            child: ListView.builder(
              controller: _verticalScrollController,
              itemCount: widget.controller.items.length,
              itemExtent: itemHeight,
              itemBuilder: (context, index) {
                final elem = widget.controller.items[index];
                late final placeholder = _buildItemPlaceholder(rowBuilder);
                return ValueAnimatedSwitcher(
                  value: elem == null,
                  duration: const Duration(milliseconds: 400),
                  child: elem == null
                      ? placeholder
                      : _buildItem(rowBuilder, elem),
                );
              },
            ),
          ),
        ),
      );

  Widget _buildItemPlaceholder(_RowBuilder rowBuilder) => Center(
        child: Shimmer.fromColors(
          baseColor: Theme.of(context).splashColor,
          highlightColor: Theme.of(context).splashColor.withOpacity(0),
          child: rowBuilder(
            Checkbox(
              value: false,
              onChanged: null,
            ),
            (col) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                width: col.width - 8.0,
                height:
                    Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildItem(_RowBuilder rowBuilder, Map<String, String> elem) {
    final key =
        widget.model.keyField == null ? null : elem[widget.model.keyField];
    final isSelected =
        key == null ? false : widget.controller.selection.contains(key);
    final foregroundColor =
        isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null;
    return ValueAnimatedSwitcher(
      key: key == null ? null : widget.controller.itemKeys[key],
      value: isSelected,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        child: InkWell(
          onTap: key == null
              ? null
              : () {
                  if (widget.controller.selection.length == 1 &&
                      widget.controller.selection.contains(key)) {
                    return;
                  }

                  widget.controller.selection.clear();
                  widget.controller.selection.add(key);
                },
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: rowBuilder(
              Checkbox(
                  value: isSelected,
                  onChanged: key == null
                      ? null
                      : (value) {
                          if (value ?? false) {
                            widget.controller.selection.add(key);
                          } else {
                            widget.controller.selection.remove(key);
                          }
                        }),
              (col) => SizedBox(
                width: col.width,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Builder(
                    builder: (context) {
                      final text = elem[col.col.name];
                      late final textWidget = text == null
                          ? null
                          : Text(
                              text,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(color: foregroundColor),
                            );

                      return col.col.props.isEmpty
                          ? textWidget ?? SizedBox()
                          : OverflowBox(
                              child: Row(
                                children: [
                                  for (final prop in col.col.props)
                                    if (prop.checkVisible(elem))
                                      OptionalTooltip(
                                        message: prop.extractLabel(elem),
                                        child: Icon(
                                          prop.icon,
                                          size: max(
                                              24.0,
                                              24.0 +
                                                  6 *
                                                      Theme.of(context)
                                                          .visualDensity
                                                          .vertical),
                                          color: foregroundColor,
                                        ),
                                      ),
                                  if (textWidget != null)
                                    Expanded(child: textWidget)
                                ],
                              ),
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableFooter() => ListenableBuilder(
        listenable: widget.controller.selection,
        builder: (context) => ListenableBuilder(
          listenable: widget.controller.items,
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.controller.selection.isEmpty
                    ? 'Всего ${widget.controller.items.length}'
                    : 'Выделено ${widget.controller.selection.length} из ${widget.controller.items.length}',
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    super.dispose();

    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
  }
}
