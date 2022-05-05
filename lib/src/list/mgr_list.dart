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

typedef MgrListColumnPressedCallback = void Function(MgrListCol col);

typedef MgrListToolbtnCallback = void Function(
  MgrListToolbtn button,
  Iterable<MgrListElemKey> keys,
);

class MgrList extends StatefulWidget {
  final MgrListModel model;
  final MgrListController controller;
  final MgrListToolbtnCallback? onToolbtnPressed;

  const MgrList({
    Key? key,
    required this.model,
    required this.controller,
    required this.onToolbtnPressed,
  }) : super(key: key);

  @override
  State<MgrList> createState() => _MgrListState();
}

class _MgrListState extends State<MgrList> {
  double _baseRowHeightScale = 1.0;
  double? _baseVerticalScrollPositionPixels;
  double _baseLocalPointY = 0.0;

  ScrollController get _verticalScrollController =>
      widget.controller.verticalTableScrollController;

  ScrollController get _horizontalScrollController =>
      widget.controller.horizontalTableScrollController;

  @override
  void initState() {
    super.initState();

    widget.controller.verticalTableScrollController
        .addListener(_dragToSelectUpdate);
  }

  @override
  void didUpdateWidget(covariant MgrList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.verticalTableScrollController
          .removeListener(_dragToSelectUpdate);
      widget.controller.verticalTableScrollController
          .addListener(_dragToSelectUpdate);
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.controller.verticalTableScrollController
        .removeListener(_dragToSelectUpdate);
  }

  static const _filterHeight = 240.0;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _buildTitle(context),
          _buildToolbar(),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.controller.isFilterOpen,
              builder: (context, isFilterOpen, child) => LayoutBuilder(
                builder: (context, constraints) {
                  bool expandFilter =
                      isFilterOpen && constraints.maxHeight <= _filterHeight;
                  return Column(
                    children: expandFilter
                        ? [Expanded(child: _buildFilter())]
                        : [
                            _buildFilter(),
                            Expanded(child: _buildTable()),
                          ],
                  );
                },
              ),
            ),
          ),
        ],
      );

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

  static const _searchTextFieldWidth = 192.0;

  Widget _buildToolbar() => LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= 3 * _searchTextFieldWidth
                ? Row(
                    children: [
                      Expanded(child: _buildToolbarButtons()),
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: SizedBox(
                          width: _searchTextFieldWidth,
                          child: Center(child: _buildToolbarSearch()),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildToolbarButtons(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildToolbarSearch(),
                      ),
                    ],
                  ),
      );

  Widget _buildToolbarButtons() => widget.onToolbtnPressed == null
      ? SizedBox()
      : Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ListenableBuilder(
              listenable: widget.controller.selection,
              builder: (context) {
                final selectionList =
                    widget.controller.selection.toList(growable: false);

                final selectedElems = List<MgrListElem?>.filled(
                  selectionList.length,
                  null,
                );

                return Row(
                  children: [
                    for (final toolgrp in widget.model.toolbar) ...[
                      const SizedBox(width: 8.0),
                      for (final toolbtn in toolgrp.buttons)
                        Builder(builder: (context) {
                          final state = toolbtn.selectionStateChecker(
                              Iterable.generate(selectedElems.length).map((i) =>
                                  selectedElems[i] ??= widget.controller.items
                                      .findElemByKey(selectionList[i])));
                          if (state == MgrListToolbtnState.hidden) {
                            return SizedBox();
                          } else {
                            final enabled = state == MgrListToolbtnState.shown;
                            return OptionalTooltip(
                              message: toolbtn.hint,
                              child: InkResponse(
                                onTap: enabled
                                    ? () async {
                                        final elems = Iterable.generate(
                                                selectionList.length)
                                            .where((i) {
                                          final elem = selectedElems[i] ??
                                              widget.controller.items
                                                  .findElemByKey(
                                                      selectionList[i]);
                                          return elem == null ||
                                              toolbtn.elemStateChecker(elem) ==
                                                  MgrListToolbtnState.shown;
                                        });

                                        if (toolbtn.confirmationRequired) {
                                          if (await showDialog<dynamic>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  scrollable: true,
                                                  content: Text(toolbtn
                                                          .confirmationMessageBuilder!(
                                                        elems.map((i) =>
                                                            selectedElems[i]),
                                                      ) ??
                                                      ''),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: Text('ОТМЕНА'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              ) !=
                                              true) {
                                            return;
                                          }
                                        }

                                        widget.onToolbtnPressed!(
                                          toolbtn,
                                          elems.map((i) => selectionList[i]),
                                        );
                                      }
                                    : null,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                              ),
                            );
                          }
                        }),
                      const SizedBox(width: 24.0),
                    ],
                  ],
                );
              },
            ),
          ),
        );

  Widget _buildToolbarSearch() => TextField(
        controller: widget.controller.searchTextEditingController,
        decoration: const InputDecoration(
          filled: true,
          labelText: 'Быстрый поиск',
        ),
      );

  Widget _buildFilter() => ValueListenableBuilder<bool>(
        valueListenable: widget.controller.isFilterOpen,
        builder: (context, isFilterOpen, child) => widget.model.filterMessage ==
                    null &&
                !isFilterOpen
            ? SizedBox()
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _filterHeight),
                child: Material(
                  type: MaterialType.card,
                  elevation: 2.0,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: InkWell(
                    onTap: isFilterOpen
                        ? null
                        : () => widget.controller.isFilterOpen.value = true,
                    child: SizedBox(
                      width: double.infinity,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56.0),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 8.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Icon(Icons.filter_alt),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: isFilterOpen
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 0.0),
                                            child: Shimmer.fromColors(
                                              baseColor:
                                                  Theme.of(context).splashColor,
                                              highlightColor: Theme.of(context)
                                                  .splashColor
                                                  .withOpacity(0),
                                              child: Wrap(
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.start,
                                                children: [
                                                  for (var i = 0; i < 16; i++)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        4.0,
                                                      ),
                                                      child: Container(
                                                        width: 240.0,
                                                        height: 48.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(8),
                                                          ),
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    )
                                                ],
                                              ),
                                            ),
                                          )
                                        : ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minHeight: 24.0,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                widget.model.filterMessage ??
                                                    '',
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 56.0,
                                height: 56.0,
                                child: IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.filter_alt_off),
                                ),
                              ),
                              SizedBox(
                                width: 56.0,
                                height: 56.0,
                                child: ExpandIcon(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  isExpanded: isFilterOpen,
                                  onPressed: (value) => widget
                                      .controller.isFilterOpen.value = !value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      );

  /// TODO
  static const _MIN_WIDTH = 200.0;
  static const _MIN_WIDTH_RATIO = 1 / 1.61803398875;

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
              final rowHeight = rowScale * 56.0 +
                  8.0 * Theme.of(context).visualDensity.vertical;

              final availableWidth = constraints.maxWidth - 16.0;

              final totalColWidth = widget.model.coldata
                      .map((e) => e.width)
                      .reduce((value, element) => value + element) +
                  rowHeight;
              final needsBreaks = totalColWidth > availableWidth;

              final factor = needsBreaks
                  ? 1.0
                  : (availableWidth - rowHeight) / (totalColWidth - rowHeight);
              final coldata = List<_Col>.unmodifiable(widget.model.coldata
                  .map((col) => _Col(col: col, width: col.width * factor)));

              if (needsBreaks) {
                final minWidth =
                    max(_MIN_WIDTH, _MIN_WIDTH_RATIO * availableWidth);

                var alternating = false;
                var leftCount = 2;
                var rightCount = 1;
                late double leftWidth;
                late double rightWidth;
                while (true) {
                  final isLeftZero = leftCount == 0;
                  final isRightZero = rightCount == 0;
                  if (leftCount + rightCount + 1 < coldata.length) {
                    if (isLeftZero && isRightZero) {
                      leftWidth = rowHeight;
                      rightWidth = 0;
                      break;
                    } else {
                      leftWidth = coldata
                              .take(leftCount)
                              .map((e) => e.width)
                              .fold<double>(
                                0.0,
                                (value, element) => value + element,
                              ) +
                          rowHeight;

                      rightWidth = coldata
                          .skip(coldata.length - rightCount)
                          .map((e) => e.width)
                          .fold<double>(
                            0.0,
                            (value, element) => value + element,
                          );
                    }

                    if (availableWidth - leftWidth - rightWidth >= minWidth) {
                      break;
                    }
                  }

                  isRightZero || (!isLeftZero && (alternating = !alternating))
                      ? leftCount--
                      : rightCount--;
                }

                final middle = List<_Col>.unmodifiable(coldata
                    .skip(leftCount)
                    .take(coldata.length - rightCount - leftCount));
                final left = List<_Col>.unmodifiable(coldata.take(leftCount));
                final right = List<_Col>.unmodifiable(
                    coldata.skip(coldata.length - rightCount));

                final middleInnerWidth = middle
                    .map((e) => e.width)
                    .reduce((value, element) => value + element);

                final isRightNonZero = rightCount != 0;
                final clipper = _MgrListRowClipper(
                  doLeft: true,
                  doRight: isRightNonZero,
                );

                final itemInnerPadding = isRightNonZero
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(right: 8.0);
                final itemOuterPadding = isRightNonZero
                    ? const EdgeInsets.symmetric(horizontal: 8.0)
                    : const EdgeInsets.only(left: 8.0);

                Widget offsetRowBuilder(ViewportOffset offset, Widget checkbox,
                    Widget builder(_Col col)) {
                  final content = ClipPath(
                    clipBehavior: Clip.hardEdge,
                    clipper: clipper,
                    child: Viewport(
                      clipBehavior: Clip.none,
                      axisDirection: AxisDirection.right,
                      crossAxisDirection: AxisDirection.down,
                      offset: offset,
                      slivers: [
                        SliverPadding(
                          padding: itemInnerPadding,
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final col = middle[index];
                                return SizedBox(
                                  width: col.width,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: builder(col),
                                  ),
                                );
                              },
                              addRepaintBoundaries: false,
                              childCount: middle.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  //print('${_horizontalScrollController.position.extentBefore} ${_horizontalScrollController.position.extentAfter}');

                  final bgColor = Theme.of(context).colorScheme.surface;
                  final dividerColor = Theme.of(context).dividerColor;

                  return Padding(
                    padding: itemOuterPadding,
                    child: Row(
                      children: [
                        SizedBox(
                          width: leftWidth,
                          child: Row(
                            children: [
                              SizedBox(
                                width: rowHeight,
                                height: double.infinity,
                                child: checkbox,
                              ),
                              ...left.map((e) => SizedBox(
                                    width: e.width,
                                    height: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: builder(e),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              content,
                              if (_horizontalScrollController
                                  .position.hasContentDimensions)
                                SizedBox(
                                  width: _dividerHedgeOffset,
                                  height: double.infinity,
                                  child: CustomPaint(
                                    painter: _MgrListRowDividerPainter(
                                      dividerColor.withOpacity(
                                          dividerColor.opacity *
                                              min(
                                                  _BREAK_DIVIDER_REVEAL_OFFSET,
                                                  _horizontalScrollController
                                                      .position.extentBefore) /
                                              _BREAK_DIVIDER_REVEAL_OFFSET),
                                      flip: false,
                                    ),
                                  ),
                                ),
                              if (_horizontalScrollController
                                      .position.hasContentDimensions &&
                                  isRightNonZero)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: _dividerHedgeOffset,
                                    height: double.infinity,
                                    child: CustomPaint(
                                      painter: _MgrListRowDividerPainter(
                                        dividerColor.withOpacity(dividerColor
                                                .opacity *
                                            ((min(
                                                    _BREAK_DIVIDER_REVEAL_OFFSET,
                                                    _horizontalScrollController
                                                        .position.extentAfter) /
                                                _BREAK_DIVIDER_REVEAL_OFFSET))),
                                        flip: true,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isRightNonZero)
                          SizedBox(
                            width: rightWidth,
                            child: Row(
                              children: [
                                ...right.map((e) => SizedBox(
                                      width: e.width,
                                      height: double.infinity,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: builder(e),
                                      ),
                                    ))
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return Scrollbar(
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
                            Divider(
                              height: 2,
                              thickness: 2,
                              indent: 16.0,
                            ),
                            _buildTableFooter(rowHeight, rowBuilder),
                          ],
                        ),
                      );
                    },
                  ),
                );
              } else {
                _RowBuilder rowBuilder = (checkbox, toWidget) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: rowHeight,
                            height: rowHeight,
                            child: checkbox,
                          ),
                          ...coldata.map((col) => SizedBox(
                                width: col.width,
                                child: toWidget(col),
                              )),
                        ],
                      ),
                    );

                return Column(
                  children: [
                    _buildTableHead(rowHeight, rowBuilder),
                    Divider(
                      height: 2,
                      thickness: 2,
                      indent: 16.0,
                    ),
                    Expanded(child: _buildTableBody(rowHeight, rowBuilder)),
                    Divider(
                      height: 2,
                      thickness: 2,
                      indent: 16.0,
                    ),
                    _buildTableFooter(rowHeight, rowBuilder),
                  ],
                );
              }
            },
          ),
        ),
      );

  Widget _buildTableHead(double itemHeight, _RowBuilder rowBuilder) => SizedBox(
        height: itemHeight,
        child: Material(
          color: Colors.transparent,
          child: rowBuilder(
            ListenableBuilder(
              listenable: widget.controller.selection,
              builder: (context) => Tooltip(
                message: widget.controller.selection.isNotEmpty
                    ? 'Снять выделение'
                    : 'Выделить все',
                child: Checkbox(
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
                        : widget.controller.selection.clear()),
              ),
            ),
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
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
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
              );
            },
          ),
        ),
      );

  bool? _dragToSelectTargetState;
  late double _dragToSelectItemHeight;
  late double _dragToSelectVerticalPosition;
  late int _dragToSelectLatestIndex;

  Widget _buildTableBody(double itemHeight, _RowBuilder rowBuilder) {
    _dragToSelectItemHeight = itemHeight;
    const dividerHeight = 1.0;

    late final placeholder = _buildTableItemPlaceholder(rowBuilder);
    return ListenableBuilder(
      listenable: widget.controller.selection,
      builder: (context) => ListenableBuilder(
        listenable: widget.controller.items,
        builder: (context) {
          final itemCount = widget.controller.items.length;
          return Stack(
            children: [
              Scrollbar(
                controller: _verticalScrollController,
                isAlwaysShown: true,
                interactive: true,
                trackVisibility: true,
                thickness: 8.0,
                radius: const Radius.circular(8.0),
                child: ListView.builder(
                  controller: _verticalScrollController,
                  addRepaintBoundaries: false,
                  itemCount: itemCount,
                  itemExtent: itemHeight,
                  itemBuilder: (context, index) {
                    final elem = widget.controller.items[index];
                    final itemWidget = ValueAnimatedSwitcher(
                      value: elem == null,
                      duration: const Duration(milliseconds: 400),
                      child: elem == null
                          ? placeholder
                          : _buildTableItem(rowBuilder, elem),
                    );

                    return index == itemCount - 1
                        ? itemWidget
                        : Stack(
                            children: [
                              itemWidget,
                              const Align(
                                alignment: Alignment.bottomLeft,
                                child: Divider(
                                  height: dividerHeight,
                                  thickness: dividerHeight,
                                  indent: 16.0,
                                  endIndent: 16.0,
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: itemHeight,
                    height: double.infinity,
                    child: GestureDetector(
                      onVerticalDragDown: (details) {
                        _dragToSelectVerticalPosition =
                            details.localPosition.dy;

                        final position = widget
                            .controller.verticalTableScrollController.position;
                        if (position.hasPixels) {
                          final index = _dragToSelectLatestIndex =
                              (position.pixels +
                                      _dragToSelectVerticalPosition) ~/
                                  _dragToSelectItemHeight;
                          final item = widget.controller.items[index];
                          if (item != null) {
                            final key = item[widget.model.keyField];
                            if (key != null) {
                              _dragToSelectTargetState =
                                  !widget.controller.selection.contains(key);
                            }
                          }
                        }
                      },
                      onVerticalDragCancel: () {
                        _dragToSelectTargetState = null;
                      },
                      onVerticalDragStart: (details) {
                        _dragToSelectVerticalPosition =
                            details.localPosition.dy;
                        _dragToSelectUpdate();
                      },
                      onVerticalDragUpdate: (details) {
                        _dragToSelectVerticalPosition =
                            details.localPosition.dy;
                        _dragToSelectUpdate();
                      },
                      onVerticalDragEnd: (details) {
                        _dragToSelectTargetState = null;
                      },
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.controller.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            widget.controller.searchPattern == null
                                ? 'Список пуст'
                                : 'Не найдено похожих элементов',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _dragToSelectUpdate() {
    final state = _dragToSelectTargetState;
    if (state == null) {
      return;
    }

    final position = widget.controller.verticalTableScrollController.position;
    if (position.hasPixels) {
      final index = min(
          widget.controller.items.length - 1,
          max(
              0,
              (position.pixels + _dragToSelectVerticalPosition) ~/
                  _dragToSelectItemHeight));

      final bool Function(int i) cmpClosure;
      final int Function(int i) incClosure;
      if (index > _dragToSelectLatestIndex) {
        cmpClosure = (i) => i <= index;
        incClosure = (i) => i + 1;
      } else {
        cmpClosure = (i) => i >= index;
        incClosure = (i) => i - 1;
      }

      for (var i = _dragToSelectLatestIndex; cmpClosure(i); i = incClosure(i)) {
        final item = widget.controller.items[i];
        if (item != null) {
          final key = item[widget.model.keyField];
          if (key != null) {
            if (state) {
              widget.controller.selection.add(key);
            } else {
              widget.controller.selection.remove(key);
            }
          }
        }
      }

      _dragToSelectLatestIndex = index;
    }
  }

  Widget _buildTableItemPlaceholder(_RowBuilder rowBuilder) => Center(
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

  Widget _buildTableItem(_RowBuilder rowBuilder, Map<String, String> elem) {
    final key =
        widget.model.keyField == null ? null : elem[widget.model.keyField];
    final isSelected =
        key == null ? false : widget.controller.selection.contains(key);
    final foregroundColor =
        isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null;
    return AnimatedContainer(
      key: ValueKey<MgrListElemKey?>(key),
      duration: const Duration(milliseconds: 200),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(0),
      child: Material(
        color: Colors.transparent,
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
          child: RepaintBoundary(
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
                (col) => Padding(
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

  Widget _buildTableFooter(double rowHeight, _RowBuilder rowBuilder) =>
      ListenableBuilder(
        listenable: widget.controller.selection,
        builder: (context) => ListenableBuilder(
          listenable: widget.controller.items,
          builder: (context) {
            final itemCount = widget.controller.items.length;
            final loadedItemCount = widget.controller.items.loadedItemCount;
            final totalText = widget.controller.searchPattern == null ||
                    itemCount == loadedItemCount
                ? '$itemCount'
                : '$loadedItemCount–$itemCount';
            final text = widget.controller.selection.isEmpty
                ? (widget.controller.searchPattern == null
                    ? 'Всего $totalText'
                    : 'Найдено $totalText')
                : 'Выделено ${widget.controller.selection.length} из $totalText';
            return ValueAnimatedSwitcher(
              value: text,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                height: rowHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _Col {
  final MgrListCol col;
  final double width;

  _Col({
    required this.col,
    required this.width,
  });
}

typedef _RowBuilder = Widget Function(
  Widget checkbox,
  Widget Function(_Col col),
);

const _dividerHedgeOffset = 8.0;
const _dividerWidth = 2.0;
const _dividerHalfWidth = _dividerWidth / 2.0;

class _MgrListRowClipper extends CustomClipper<Path> {
  final bool doLeft, doRight;

  _MgrListRowClipper({
    required this.doLeft,
    required this.doRight,
  });

  @override
  Path getClip(Size size) {
    late final oneForthHeight = size.height / 4;
    late final halfHeight = 2 * oneForthHeight;
    late final twoThirdsHeight = 3 * oneForthHeight;
    final rightEdge = size.width - _dividerHalfWidth;

    final path = Path()
      ..moveTo(_dividerHalfWidth, 0)
      ..lineTo(rightEdge, 0);

    if (doRight) {
      final rightOffsetEdge =
          size.width - _dividerHedgeOffset - _dividerHalfWidth;

      path
        ..lineTo(rightOffsetEdge, oneForthHeight)
        ..lineTo(rightEdge, halfHeight)
        ..lineTo(rightOffsetEdge, twoThirdsHeight);
    }

    path
      ..lineTo(rightEdge, size.height)
      ..lineTo(_dividerHalfWidth, size.height);

    if (doLeft) {
      final leftOffsetEdge = _dividerHedgeOffset + _dividerHalfWidth;

      path
        ..lineTo(leftOffsetEdge, twoThirdsHeight)
        ..lineTo(_dividerHalfWidth, halfHeight)
        ..lineTo(leftOffsetEdge, oneForthHeight);
    }

    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _MgrListRowClipper oldClipper) =>
      oldClipper.doLeft != doLeft || oldClipper.doRight != doRight;
}

class _MgrListRowDividerPainter extends CustomPainter {
  final Color color;
  final bool flip;

  _MgrListRowDividerPainter(
    this.color, {
    required this.flip,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color.opacity > 0) {
      final oneForthHeight = size.height / 4;
      canvas.drawPath(
          flip
              ? (Path()
                ..moveTo(size.width, 0)
                ..lineTo(0, oneForthHeight)
                ..lineTo(size.width, 2 * oneForthHeight)
                ..lineTo(0, 3 * oneForthHeight)
                ..lineTo(size.width, size.height))
              : (Path()
                ..lineTo(size.width, oneForthHeight)
                ..lineTo(0, 2 * oneForthHeight)
                ..lineTo(size.width, 3 * oneForthHeight)
                ..lineTo(0, size.height)),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt
            ..strokeWidth = _dividerWidth);
    }
  }

  @override
  bool shouldRepaint(covariant _MgrListRowDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}
