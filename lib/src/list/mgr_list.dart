import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mgr5/extensions/iterator_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/mgr5_form.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_field.dart';
import 'package:flutter_mgr5/src/form/mgr_form_field_hint_mode.dart';
import 'package:flutter_mgr5/src/list/mgr_list_controller.dart';
import 'package:flutter_mgr5/src/list/mgr_list_model.dart';
import 'package:flutter_mgr5/src/optional_tooltip.dart';
import 'package:flutter_mgr5/value_animated_switcher.dart';
import 'package:material_table_view/default_animated_switcher_transition_builder.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/shimmer_placeholder_shade.dart';
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
  final MgrFormModel? filterModel;
  final MgrFormController? filterController;
  final VoidCallback? onFilterSubmitPressed;
  final VoidCallback? onFilterDisablePressed;

  const MgrList({
    Key? key,
    required this.model,
    required this.controller,
    required this.filterModel,
    required this.filterController,
    required this.onToolbtnPressed,
    required this.onFilterSubmitPressed,
    required this.onFilterDisablePressed,
  }) : super(key: key);

  @override
  State<MgrList> createState() => _MgrListState();
}

class _MgrListState extends State<MgrList> {
  final _colTotals = <String, String>{};

  double _baseRowHeightScale = 1.0;
  double? _baseVerticalScrollPositionPixels;
  double _baseLocalPointY = 0.0;

  ScrollController get _verticalScrollController =>
      widget.controller.tableViewController.verticalScrollController;

  ScrollController get _horizontalScrollController =>
      widget.controller.tableViewController.horizontalScrollController;

  @override
  void initState() {
    super.initState();

    widget.controller.items.addListener(_resetTotals);
    widget.controller.selection.addListener(_resetTotals);

    widget.controller.tableViewController.verticalScrollController
        .addListener(_dragToSelectUpdate);
  }

  @override
  void didUpdateWidget(covariant MgrList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.items.removeListener(_resetTotals);
      widget.controller.items.addListener(_resetTotals);
      oldWidget.controller.selection.removeListener(_resetTotals);
      widget.controller.selection.addListener(_resetTotals);

      oldWidget.controller.tableViewController.verticalScrollController
          .removeListener(_dragToSelectUpdate);
      widget.controller.tableViewController.verticalScrollController
          .addListener(_dragToSelectUpdate);
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.controller.tableViewController.verticalScrollController
        .removeListener(_dragToSelectUpdate);
  }

  void _resetTotals() => _colTotals.clear();

  String? _totalFor(MgrListCol col) {
    if (col.total == null || widget.controller.selection.isEmpty) {
      return null;
    }

    final cached = _colTotals[col.name];
    if (cached != null) {
      return cached;
    }

    final items = widget.controller.selection
        .map((e) => widget.controller.items.findElemByKey(e))
        .whereNotNull()
        .map((e) => e[col.name])
        .whereNotNull()
        .map((e) => double.tryParse(e.replaceAll(' ', '')))
        .whereNotNull();

    if (items.isEmpty) {
      return _colTotals[col.name] = '';
    }

    final String total;
    switch (col.total) {
      case MgrListColTotal.sum:
        total = items.fold<double>(0.0, (a, b) => a + b).toString();
        break;
      case MgrListColTotal.sumRound:
        total = items.fold<double>(0.0, (a, b) => a + b).round().toString();
        break;
      case MgrListColTotal.average:
        var count = 0;
        var subtotal = 0.0;
        for (final item in items) {
          count++;
          subtotal += item;
        }

        total = (subtotal / count).toString();
        break;
      case null:
        return null;
    }

    return _colTotals[col.name] = total;
  }

  static const _checkboxWidth = 36.0;
  static const _filterHeight = 480.0;

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => widget.controller.items.clear(),
                  icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
      );

  static const _searchTextFieldWidth = 192.0;

  Widget _buildToolbar() {
    final filterToolbtn = widget.model.toolbar
        .expand((toolgrp) => toolgrp.buttons)
        .where((toolbtn) => toolbtn.name == 'filter')
        .maybeFirst;

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >=
              3 * _searchTextFieldWidth
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
                if (filterToolbtn != null && widget.model.filterMessage == null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      onPressed: () =>
                          widget.controller.isFilterOpen.value ^= true,
                      icon: const Icon(Icons.filter_alt),
                    ),
                  ),
              ],
            )
          : Column(
              children: [
                _buildToolbarButtons(),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildToolbarSearch(),
                      ),
                    ),
                    if (filterToolbtn != null &&
                        widget.model.filterMessage == null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: IconButton(
                          onPressed: () =>
                              widget.controller.isFilterOpen.value ^= true,
                          icon: const Icon(Icons.filter_alt),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildToolbarButtons() => widget.onToolbtnPressed == null
      ? const SizedBox()
      : Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ListenableBuilder(
              listenable: widget.controller.selection,
              builder: (context, _) {
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
                        if (toolbtn.name != 'filter')
                          Builder(
                            builder: (context) {
                              final state = toolbtn.selectionStateChecker(
                                  Iterable.generate(selectedElems.length).map(
                                      (i) => selectedElems[i] ??= widget
                                          .controller.items
                                          .findElemByKey(selectionList[i])));
                              if (state == MgrListToolbtnState.hidden) {
                                return const SizedBox();
                              } else {
                                final enabled =
                                    state == MgrListToolbtnState.shown;
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
                                                  toolbtn.elemStateChecker(
                                                          elem) ==
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
                                                                selectedElems[
                                                                    i]),
                                                          ) ??
                                                          ''),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: const Text(
                                                              'ОТМЕНА'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          child:
                                                              const Text('OK'),
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
                                              elems
                                                  .map((i) => selectionList[i]),
                                            );
                                          }
                                        : null,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
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
                                                          const TextStyle())
                                                      .copyWith(
                                                          color: enabled
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface
                                                              : Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      .5)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
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
            ? const SizedBox()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isVertical = constraints.maxWidth <= 512;
                  late final form = widget.filterModel == null ||
                          widget.filterController == null
                      ? SingleChildScrollView(
                          child: Shimmer.fromColors(
                            baseColor: Theme.of(context).splashColor,
                            highlightColor:
                                Theme.of(context).splashColor.withOpacity(0),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children: [
                                for (var i = 0; i < 16; i++)
                                  Padding(
                                    padding: const EdgeInsets.all(
                                      4.0,
                                    ),
                                    child: Container(
                                      width: 240.0,
                                      height: 48.0,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
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
                      : _MgrListFilterForm(
                          model: widget.filterModel!,
                          controller: widget.filterController!,
                        );

                  Widget body = Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 16.0,
                          ),
                          child: Icon(Icons.filter_alt),
                        ),
                        Expanded(
                          child: isFilterOpen
                              ? isVertical
                                  ? const SizedBox()
                                  : form
                              : Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: IntrinsicHeight(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 24.0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          widget.model.filterMessage ?? '',
                                          textAlign: TextAlign.start,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        IntrinsicHeight(
                          child: IntrinsicWidth(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (widget.onFilterDisablePressed != null &&
                                        widget.model.filterMessage != null)
                                      SizedBox(
                                        width: 56.0,
                                        height: 56.0,
                                        child: IconButton(
                                          onPressed:
                                              widget.onFilterDisablePressed,
                                          icon:
                                              const Icon(Icons.filter_alt_off),
                                        ),
                                      ),
                                    SizedBox(
                                      width: 56.0,
                                      height: 56.0,
                                      child: ExpandIcon(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        isExpanded: isFilterOpen,
                                        onPressed: (value) => widget.controller
                                            .isFilterOpen.value = !value,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isFilterOpen && !isVertical) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      top: 8.0,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: widget.onFilterSubmitPressed,
                                        child: const Text('НАЙТИ'),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      top: 16.0,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => widget
                                            .filterController!.params
                                            .clear(),
                                        child: const Text('ОЧИСТИТЬ'),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isVertical && isFilterOpen) {
                    body = Column(
                      children: [
                        body,
                        const Divider(
                          height: 2.0,
                          thickness: 2.0,
                          indent: 16.0,
                        ),
                        Expanded(child: form),
                        const Divider(
                          height: 2.0,
                          thickness: 2.0,
                          indent: 16.0,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            direction: Axis.horizontal,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: OutlinedButton(
                                  onPressed: () =>
                                      widget.filterController!.params.clear(),
                                  child: const Text('ОЧИСТИТЬ'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: OutlinedButton(
                                  onPressed: widget.onFilterSubmitPressed,
                                  child: const Text('НАЙТИ'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ConstrainedBox(
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
                            child: body,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      );

  /// TODO
  static const _MIN_WIDTH = 200.0;
  static const _MIN_WIDTH_RATIO = 1 / 1.61803398875;

  /// TODO
  static const _BREAK_DIVIDER_REVEAL_OFFSET = 8.0;

  static const shimmerBaseColor = Color(0x20808080);
  static const shimmerHighlightColor = Color(0x40FFFFFF);

  Widget _buildTable() => ShimmerPlaceholderShadeProvider(
        loopDuration: const Duration(seconds: 2),
        colors: const [
          shimmerBaseColor,
          shimmerHighlightColor,
          shimmerBaseColor,
          shimmerHighlightColor,
          shimmerBaseColor
        ],
        stops: const [.0, .45, .5, .95, 1],
        builder: (context, placeholderShade) => GestureDetector(
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
            final clampedValue = widget.controller.rowHeightScale.value =
                max(.5, min(1.0, value));
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
                final rowHeight = rowScale * 48.0 +
                    4.0 * Theme.of(context).visualDensity.vertical;
                _dragToSelectRowHeight = rowHeight;

                final availableWidth = constraints.maxWidth - 16.0;

                final totalColWidth = widget.model.coldata
                        .map((e) => e.width)
                        .fold<double>(
                            0.0, (value, element) => value + element) +
                    _checkboxWidth;
                final needsBreaks = totalColWidth > availableWidth;

                final widthFactor = needsBreaks
                    ? 1.0
                    : (availableWidth - _checkboxWidth) /
                        (totalColWidth - _checkboxWidth);

                final minWidth =
                    max(_MIN_WIDTH, _MIN_WIDTH_RATIO * availableWidth);

                final bgColor = Theme.of(context).colorScheme.surface;
                final dividerColor = Theme.of(context).dividerColor;

                final coldata = widget.model.coldata;

                return ListenableBuilder(
                  listenable: widget.controller.selection,
                  builder: (context, _) => ListenableBuilder(
                    listenable: widget.controller.items,
                    builder: (context, _) => TableView.builder(
                      controller: widget.controller.tableViewController,
                      rowCount: widget.controller.items.length,
                      rowHeight: rowHeight,
                      placeholderShade: placeholderShade,
                      minScrollableWidth: minWidth,
                      columns: [
                        TableColumn(
                          width: _checkboxWidth,
                          freezePriority: coldata.length,
                        ),
                        for (var i = 0; i < coldata.length; i++)
                          TableColumn(
                            width: widthFactor * coldata[i].width,
                            freezePriority:
                                [0, 1, coldata.length - 1].contains(i)
                                    ? coldata.length - i
                                    : 0,
                          ),
                      ],
                      bodyContainerBuilder: (context, body) => Stack(
                        fit: StackFit.expand,
                        children: [
                          body,
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: _checkboxWidth,
                                height: double.infinity,
                                child: GestureDetector(
                                  onVerticalDragDown: (details) {
                                    _dragToSelectVerticalPosition =
                                        details.localPosition.dy;

                                    final position = widget
                                        .controller
                                        .tableViewController
                                        .verticalScrollController
                                        .position;
                                    if (position.hasPixels) {
                                      final index = _dragToSelectLatestIndex =
                                          (position.pixels +
                                                  _dragToSelectVerticalPosition) ~/
                                              _dragToSelectRowHeight;
                                      final item =
                                          widget.controller.items[index];
                                      if (item != null) {
                                        final key = item[widget.model.keyField];
                                        if (key != null) {
                                          _dragToSelectTargetState = !widget
                                              .controller.selection
                                              .contains(key);
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
                      ),
                      rowBuilder: (context, row, contentBuilder) {
                        final elem = widget.controller.items[row];
                        if (elem == null) {
                          return null;
                        }
                        final key = widget.model.keyField == null
                            ? null
                            : elem[widget.model.keyField];
                        final isSelected = key == null
                            ? false
                            : widget.controller.selection.contains(key);
                        final foregroundColor = isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null;
                        return AnimatedContainer(
                          key: ValueKey<MgrListElemKey?>(key),
                          duration: const Duration(milliseconds: 200),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0),
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: key == null
                                  ? null
                                  : () {
                                      if (widget.controller.selection.length ==
                                              1 &&
                                          widget.controller.selection
                                              .contains(key)) {
                                        return;
                                      }

                                      widget.controller.selection.clear();
                                      widget.controller.selection.add(key);
                                    },
                              child: SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: contentBuilder(
                                  context,
                                  (context, column) {
                                    if (column == 0) {
                                      return Checkbox(
                                          value: isSelected,
                                          onChanged: key == null
                                              ? null
                                              : (value) {
                                                  if (value ?? false) {
                                                    widget.controller.selection
                                                        .add(key);
                                                  } else {
                                                    widget.controller.selection
                                                        .remove(key);
                                                  }
                                                });
                                    } else {
                                      final col =
                                          widget.model.coldata[column - 1];
                                      return Padding(
                                        padding: _cellPadding(col),
                                        child: Builder(
                                          builder: (context) {
                                            final text = elem[col.name];
                                            late final textWidget = text == null
                                                ? null
                                                : Text(
                                                    text,
                                                    maxLines: 1,
                                                    softWrap: false,
                                                    overflow: TextOverflow.fade,
                                                    style: TextStyle(
                                                        color: foregroundColor),
                                                    textAlign: col.textAlign,
                                                  );

                                            return col.props.isEmpty
                                                ? Align(
                                                    alignment: col.alignment,
                                                    child: textWidget ??
                                                        const SizedBox(),
                                                  )
                                                : OverflowBox(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          col.mainAxisAlignment,
                                                      children: [
                                                        for (final prop
                                                            in col.props)
                                                          if (prop.checkVisible(
                                                              elem))
                                                            OptionalTooltip(
                                                              message: prop
                                                                  .extractLabel(
                                                                      elem),
                                                              child: Icon(
                                                                prop.icon,
                                                                size: max(
                                                                    24.0,
                                                                    24.0 +
                                                                        6 * Theme.of(context).visualDensity.vertical),
                                                                color:
                                                                    foregroundColor,
                                                              ),
                                                            ),
                                                        if (textWidget != null)
                                                          Expanded(
                                                              child: textWidget)
                                                      ],
                                                    ),
                                                  );
                                          },
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      placeholderBuilder: (context, contentBuilder) =>
                          contentBuilder(
                        context,
                        (context, column) {
                          if (column == 0) {
                            return const Checkbox(
                              value: false,
                              onChanged: null,
                            );
                          }

                          final col = coldata[column - 1];
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                width: col.width - 8.0,
                                height: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.fontSize ??
                                    16.0,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                  color: Color(0x80808080),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      headerBuilder: (context, contentBuilder) => Material(
                        type: MaterialType.transparency,
                        child: contentBuilder(
                          context,
                          (context, column) {
                            if (column == 0) {
                              return ListenableBuilder(
                                listenable: widget.controller.selection,
                                builder: (context, _) => Tooltip(
                                  message:
                                      widget.controller.selection.isNotEmpty
                                          ? 'Снять выделение'
                                          : 'Выделить все',
                                  child: Checkbox(
                                      value: widget
                                              .controller.selection.isNotEmpty
                                          ? (widget.controller.selection
                                                      .length ==
                                                  widget.controller.items.length
                                              ? true
                                              : null)
                                          : false,
                                      tristate: true,
                                      onChanged: (value) => value ?? false
                                          ? widget.controller.selection.addAll(
                                              widget.controller.items
                                                  .map((e) =>
                                                      e?[widget.model.keyField])
                                                  .whereNotNull())
                                          : widget.controller.selection
                                              .clear()),
                                ),
                              );
                            }

                            final col = widget.model.coldata[column - 1];
                            final text = Text(
                              col.label ?? '',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: Theme.of(context).textTheme.titleSmall,
                              textAlign: col.textAlign,
                            );

                            return Material(
                              type: MaterialType.transparency,
                              child: OptionalTooltip(
                                message: col.hint,
                                child: InkResponse(
                                  radius: col.width / 2,
                                  onTap: () {},
                                  child: Padding(
                                    padding: _cellPadding(col),
                                    child: Align(
                                      alignment: col.alignment,
                                      child: col.sorted == null
                                          ? text
                                          : Row(
                                              mainAxisAlignment:
                                                  col.mainAxisAlignment,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Flexible(child: text),
                                                col.sorted!.index == 1
                                                    ? Icon(col.sorted!.ascending
                                                        ? Icons.arrow_drop_up
                                                        : Icons.arrow_drop_down)
                                                    : Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 8.0),
                                                            child: Icon(col
                                                                    .sorted!
                                                                    .ascending
                                                                ? Icons
                                                                    .arrow_drop_up
                                                                : Icons
                                                                    .arrow_drop_down),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    bottom:
                                                                        8.0),
                                                            child: Text(
                                                              col.sorted!.index
                                                                  .toString(),
                                                              style: Theme.of(
                                                                      context)
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
                      footerBuilder: (context, contentBuilder) =>
                          ListenableBuilder(
                        listenable: widget.controller.selection,
                        builder: (context, _) => ListenableBuilder(
                          listenable: widget.controller.items,
                          builder: (context, _) {
                            final itemCount = widget.controller.items.length;
                            final loadedItemCount =
                                widget.controller.items.loadedItemCount;
                            final totalText =
                                widget.controller.searchPattern == null ||
                                        itemCount == loadedItemCount
                                    ? '$itemCount'
                                    : '$loadedItemCount–$itemCount';
                            final text = widget.controller.selection.isEmpty
                                ? (widget.controller.searchPattern == null
                                    ? 'Всего $totalText'
                                    : 'Найдено $totalText')
                                : 'Выделено ${widget.controller.selection.length} из $totalText';
                            return SizedBox(
                              height: rowHeight,
                              child: Stack(
                                children: [
                                  contentBuilder(context, (context, column) {
                                    if (column == 0) {
                                      return const SizedBox();
                                    }

                                    final col = coldata[column - 1];
                                    late final total = _totalFor(col);
                                    return ValueAnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      value: total,
                                      child: total == null || total.isEmpty
                                          ? const SizedBox(
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : Padding(
                                              padding: _cellPadding(col),
                                              child: Align(
                                                alignment: col.alignment,
                                                child: Text(
                                                  total,
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  overflow: TextOverflow.fade,
                                                  textAlign: col.textAlign,
                                                ),
                                              ),
                                            ),
                                    );
                                  }),
                                  ValueAnimatedSwitcher(
                                    value: text,
                                    transitionBuilder:
                                        tableRowDefaultAnimatedSwitcherTransitionBuilder,
                                    duration: const Duration(milliseconds: 200),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
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
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  EdgeInsets _cellPadding(MgrListCol col) {
    switch (col.textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return const EdgeInsets.only(left: 8.0);
      case TextAlign.right:
      case TextAlign.end:
        return const EdgeInsets.only(right: 8.0);
      case TextAlign.center:
      case TextAlign.justify:
        return const EdgeInsets.symmetric(horizontal: 8.0);
    }
  }

  bool? _dragToSelectTargetState;
  late double _dragToSelectRowHeight;
  late double _dragToSelectVerticalPosition;
  late int _dragToSelectLatestIndex;

  void _dragToSelectUpdate() {
    final state = _dragToSelectTargetState;
    if (state == null) {
      return;
    }

    final position =
        widget.controller.tableViewController.verticalScrollController.position;
    if (position.hasPixels) {
      final index = min(
          widget.controller.items.length - 1,
          max(
              0,
              (position.pixels + _dragToSelectVerticalPosition) ~/
                  _dragToSelectRowHeight));

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
}

class _MgrListFilterForm extends StatelessWidget {
  final MgrFormModel model;
  final MgrFormController controller;

  const _MgrListFilterForm({
    Key? key,
    required this.model,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MgrFormState state;
    return FocusTraversalGroup(
      child: Scrollbar(
        controller: controller.scrollController,
        trackVisibility: true,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 2.0),
              controller: controller.scrollController,
              children: [
                for (final page in model.pages)
                  if (!page.isHidden &&
                      (state = page.name == null
                              ? MgrFormState.visible
                              : model.getStateChecker(page.name!)(
                                  controller.stringParams)) !=
                          MgrFormState.gone)
                    _buildPage(page, state == MgrFormState.readOnly),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage(MgrFormPageModel page, bool forceReadOnly) => Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const preferredLabelWidth = 120.0;
            const preferredControlWidth = 192.0;
            const additionalFieldWidth = 32.0 + 16.0;

            final countX = constraints.maxWidth ~/
                (preferredLabelWidth +
                    preferredControlWidth +
                    additionalFieldWidth);
            final fieldWidth = countX == 0
                ? constraints.maxWidth
                : constraints.maxWidth / countX;
            final controlWidth = countX == 0
                ? (fieldWidth - additionalFieldWidth) / 2
                : fieldWidth - preferredLabelWidth - additionalFieldWidth;
            final labelWidth = countX == 0
                ? fieldWidth - additionalFieldWidth - controlWidth
                : preferredLabelWidth;

            MgrFormState state;
            return controlWidth < 0 || labelWidth < 0
                ? const SizedBox()
                : Wrap(
                    runAlignment: WrapAlignment.spaceEvenly,
                    children: [
                      for (final field in page.fields)
                        if ((state = model.getStateChecker(field.name)(
                                controller.stringParams)) !=
                            MgrFormState.gone)
                          SizedBox(
                            width: fieldWidth,
                            child: MgrFormField(
                              controller: controller,
                              model: field,
                              exceptionHolder: null,
                              hintMode: MgrFormFieldHintMode.floating,
                              labelWidth: labelWidth,
                              controlsWidth: controlWidth,
                              forceReadOnly: forceReadOnly ||
                                  state == MgrFormState.readOnly,
                              forceFullWidth: false,
                            ),
                          ),
                    ],
                  );
          },
        ),
      );
}
