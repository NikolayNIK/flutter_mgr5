import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/animated_rect_reveal.dart';
import 'package:flutter_mgr5/src/form/slist.dart';

typedef MgrFormSelectMultiOnChanged = void Function();

class MgrFormSelectMulti extends StatefulWidget {
  final MgrMultiSelectController controller;
  final double itemHeight;
  final FocusNode? focusNode;
  final bool readOnly;
  final BorderRadius borderRadius;

  const MgrFormSelectMulti({
    super.key,
    required this.controller,
    required this.itemHeight,
    required this.readOnly,
    this.borderRadius = const BorderRadius.all(Radius.circular(2.0)),
    this.focusNode,
  });

  @override
  State<MgrFormSelectMulti> createState() => _MgrFormSelectMultiState();
}

class _MgrFormSelectMultiState extends State<MgrFormSelectMulti> {
  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          focusNode: widget.focusNode,
          borderRadius: widget.borderRadius,
          onTap: widget.readOnly ? null : _onTap,
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: IntrinsicHeight(
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ListenableBuilder(
                                listenable: widget.controller,
                                builder: (context, _) =>
                                    _buildSelectionChips(context, false),
                              ),
                            ),
                            Icon(
                              color: !widget.readOnly
                                  ? Theme.of(context).disabledColor
                                  : null,
                              Icons.arrow_drop_down,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0.0,
                right: 0.0,
                bottom: 0.0, // TODO 8.0?
                child: Container(
                  height: 1.0,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFBDBDBD),
                        width: 0.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSelectionChips(BuildContext context, bool removable) => Align(
        alignment: Alignment.centerLeft,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.controller.selection.isEmpty
                ? // TODO localize
                const Text('-- не указано --')
                : Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      final backgroundColor =
                          theme.colorScheme.primaryContainer.withOpacity(2 / 3);
                      final foregroundColor =
                          theme.colorScheme.onPrimaryContainer;
                      final labelTextTheme = Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: foregroundColor);

                      final result = RepaintBoundary(
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 8.0,
                          runSpacing: 8.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runAlignment: WrapAlignment.center,
                          children: [
                            for (final entry
                                in widget.controller.selection
                                    .toList(growable: false)
                                  ..sort((a, b) {
                                    final cmp = a.label.length
                                        .compareTo(b.label.length);
                                    return cmp == 0
                                        ? a.label.compareTo(b.label)
                                        : cmp;
                                  }))
                              Material(
                                type: MaterialType.card,
                                color: backgroundColor,
                                clipBehavior: Clip.hardEdge,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(32.0),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: removable
                                      ? () => widget.controller.selection
                                          .remove(entry)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    child: IntrinsicWidth(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              entry.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.fade,
                                              softWrap: false,
                                              style: labelTextTheme,
                                            ),
                                          ),
                                          if (removable)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4.0),
                                              child: Icon(
                                                Icons.close,
                                                size: 12,
                                                color: foregroundColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );

                      return removable ? result : IgnorePointer(child: result);
                    },
                  ),
          ),
        ),
      );

  Widget _buildItem(BuildContext context, SlistEntry entry, bool selected) {
    final textStyle = Theme.of(context).textTheme.titleMedium!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DefaultTextStyle(
        style: entry.textColor != null
            ? textStyle.copyWith(color: entry.textColor)
            : selected
                ? textStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer)
                : textStyle,
        child: Builder(
          builder: (context) => Text(
            entry.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _onTap() {
    widget.focusNode?.requestFocus();

    final navigator = Navigator.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final rect = renderBox.localToGlobal(Offset.zero,
            ancestor: navigator.context.findRenderObject()) &
        renderBox.size;

    navigator.push(_DropdownRoute(
      controller: widget.controller,
      buttonRect: rect,
      itemHeight: widget.itemHeight,
      itemBuilder: _buildItem,
      selectionClipsBuilder: _buildSelectionChips,
    ));
  }
}

class _DropdownRoute extends PopupRoute<void> {
  final Rect buttonRect;
  final double itemHeight;
  final MgrMultiSelectController _controller;
  final Widget Function(
    BuildContext context,
    SlistEntry entry,
    bool selected,
  ) itemBuilder;
  final Widget Function(
    BuildContext context,
    bool removable,
  ) selectionClipsBuilder;

  _DropdownRoute({
    required this.buttonRect,
    required MgrMultiSelectController controller,
    required this.itemHeight,
    required this.itemBuilder,
    required this.selectionClipsBuilder,
  }) : _controller = controller;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      _DropdownPage(
        animation: animation,
        buttonRect: buttonRect,
        controller: _controller,
        itemHeight: itemHeight,
        itemBuilder: itemBuilder,
        selectionClipsBuilder: selectionClipsBuilder,
      );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);
}

class _DropdownPage extends StatefulWidget {
  final Animation<double> animation;
  final Rect buttonRect;
  final double itemHeight;
  final MgrMultiSelectController controller;
  final Widget Function(
    BuildContext context,
    SlistEntry entry,
    bool selected,
  ) itemBuilder;
  final Widget Function(
    BuildContext context,
    bool removable,
  ) selectionClipsBuilder;

  const _DropdownPage({
    required this.animation,
    required this.buttonRect,
    required this.controller,
    required this.itemHeight,
    required this.itemBuilder,
    required this.selectionClipsBuilder,
  });

  @override
  State<_DropdownPage> createState() => _DropdownPageState();
}

class _DropdownPageState extends State<_DropdownPage> {
  static const _windowMargin = EdgeInsets.all(16.0);

  final searchController = TextEditingController();
  final focusSearch = FocusNode();
  final selectionChipsScrollController = ScrollController();
  final scrollController = ScrollController();
  late List<SlistEntry> entries;

  @override
  void initState() {
    super.initState();

    focusSearch.requestFocus();

    _updateEntries();
    searchController.addListener(_updateEntries);
    widget.controller.slist.addListener(_updateEntries);
  }

  @override
  void didUpdateWidget(covariant _DropdownPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller.slist != widget.controller.slist) {
      oldWidget.controller.slist.removeListener(_updateEntries);
      widget.controller.slist.addListener(_updateEntries);
    }
  }

  @override
  void dispose() {
    super.dispose();

    widget.controller.slist.removeListener(_updateEntries);

    searchController.dispose();
    focusSearch.dispose();
  }

  void _updateEntries() => setState(() {
        final searchPattern = searchController.text.trim().toLowerCase();
        if (!searchEnabled || searchPattern.isEmpty) {
          entries = widget.controller.slist.value;
        } else {
          entries = widget.controller.slist.value
              .where((element) => element.containsText(searchPattern))
              .toList(growable: false);
        }
      });

  bool get searchEnabled => widget.controller.slist.value.length > 4;

  double get leftMarkerWidth =>
      56.0 + 4.0 * Theme.of(context).visualDensity.horizontal;

  double get searchFieldHeight =>
      56.0 + 4.0 * Theme.of(context).visualDensity.horizontal;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const selectionChipsSectionHeight = 88.0;

            // TODO это все такие костыли...

            final buttonRect = Rect.fromLTRB(
              max(_windowMargin.left, widget.buttonRect.left),
              max(_windowMargin.top + selectionChipsSectionHeight,
                  widget.buttonRect.top),
              min(constraints.maxWidth - _windowMargin.right,
                  widget.buttonRect.right),
              min(constraints.maxHeight - _windowMargin.bottom,
                  widget.buttonRect.bottom),
            );

            // TODO улучшить расчет максимальной ширины элемента);
            var rect = Rect.fromLTWH(
                buttonRect.left - leftMarkerWidth,
                buttonRect.top - selectionChipsSectionHeight,
                min(
                    constraints.maxWidth -
                        _windowMargin.right -
                        buttonRect.left +
                        leftMarkerWidth,
                    max(buttonRect.width + 2 * leftMarkerWidth,
                        widget.controller.longestLabelLength * 11.0)),
                min(
                    constraints.maxHeight -
                        _windowMargin.bottom -
                        buttonRect.top +
                        selectionChipsSectionHeight,
                    (1 + entries.length) * widget.itemHeight +
                        selectionChipsSectionHeight +
                        (searchEnabled ? searchFieldHeight : 0)));

            if (rect.height <
                widget.itemHeight * min(entries.length, 6.5) +
                    (searchEnabled ? searchFieldHeight : 0)) {
              final newTop = max(
                  _windowMargin.top,
                  rect.top -
                      widget.itemHeight * min(entries.length, 6.5) -
                      (searchEnabled ? searchFieldHeight : 0) +
                      rect.height);

              rect = Rect.fromLTRB(
                rect.left,
                newTop,
                rect.right,
                rect.bottom,
              );
            }

            if (rect.width < buttonRect.width + 2 * leftMarkerWidth) {
              final newLeft = max(
                  _windowMargin.left,
                  rect.left -
                      buttonRect.width -
                      2 * leftMarkerWidth +
                      rect.width);

              rect = Rect.fromLTRB(
                newLeft,
                rect.top,
                rect.right,
                rect.bottom,
              );
            }

            return AnimatedRectReveal.builder(
              animation: widget.animation
                  .drive(CurveTween(curve: Curves.fastOutSlowIn)),
              originBox: widget.buttonRect,
              destinationBox: rect,
              containerBuilder: (context, child) => Material(
                elevation: 8.0,
                type: MaterialType.card,
                shadowColor: Colors.black,
                clipBehavior: Clip.hardEdge,
                child: child,
              ),
              contentOffset: Offset(
                widget.buttonRect.left - rect.left - 8.0,
                selectionChipsSectionHeight,
              ),
              builder: (context, offset, child) => ClipRect(
                child: Transform.translate(
                  offset: offset,
                  child: RepaintBoundary(
                    child: child,
                  ),
                ),
              ),
              child: Material(
                child: Column(
                  children: [
                    SizedBox(
                      height: selectionChipsSectionHeight,
                      child: Scrollbar(
                        controller: selectionChipsScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: selectionChipsScrollController,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 16,
                              right: 16,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child:
                                  widget.selectionClipsBuilder(context, true),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (searchEnabled)
                      RepaintBoundary(child: _buildSearch(context)),
                    Flexible(
                      child: ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) => Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: scrollController,
                            shrinkWrap: true,
                            itemExtent: widget.itemHeight,
                            itemCount: entries.length + 1,
                            itemBuilder: (context, index) => index == 0
                                ? Material(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer
                                        .withOpacity(
                                            widget.controller.selection.length /
                                                widget.controller.slist.value
                                                    .length),
                                    child: InkWell(
                                      onTap: _onClickSelectAll,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: leftMarkerWidth,
                                            height: widget.itemHeight,
                                            child: Checkbox(
                                              value: widget.controller.selection
                                                      .isEmpty
                                                  ? false
                                                  : widget.controller.selection
                                                              .length ==
                                                          widget
                                                              .controller
                                                              .slist
                                                              .value
                                                              .length
                                                      ? true
                                                      : null,
                                              tristate: true,
                                              onChanged: (value) =>
                                                  _onClickSelectAll(),
                                            ),
                                          ),
                                          Expanded(
                                            // TODO
                                            child: Text(
                                              '-- выделить все ---',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : _buildItem(
                                    context, index - 1, entries[index - 1]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildSearch(BuildContext context) => SizedBox(
        height: searchFieldHeight,
        child: Stack(
          children: [
            SizedBox(
              width: leftMarkerWidth,
              child: const Center(
                child: Icon(Icons.search_rounded),
              ),
            ),
            TextField(
              focusNode: focusSearch,
              controller: searchController,
              maxLines: 1,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(
                  left: leftMarkerWidth + 8.0,
                  right: 8.0,
                ),
              ),
              textInputAction: entries.length == 1
                  ? TextInputAction.send
                  : TextInputAction.none,
            ),
          ],
        ),
      );

  Widget _buildItem(BuildContext context, int index, SlistEntry entry) {
    final selected = widget.controller.selection.contains(entry);

    return Material(
      key: ValueKey<String?>(entry.key),
      type: MaterialType.canvas,
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: () => _onTap(context, index, entry),
        child: Row(
          children: [
            SizedBox(
              width: leftMarkerWidth,
              height: widget.itemHeight,
              child: Center(
                child: Checkbox(
                  value: selected,
                  onChanged: (value) => _onTap(context, index, entry),
                ),
              ),
            ),
            Expanded(
              child: widget.itemBuilder(context, entry, selected),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index, SlistEntry entry) {
    if (!widget.controller.selection.remove(entry)) {
      widget.controller.selection.add(entry);
    }
  }

  void _onClickSelectAll() {
    if (widget.controller.selection.isEmpty) {
      widget.controller.selection.addAll(widget.controller.slist.value);
    } else {
      widget.controller.selection.clear();
    }
  }
}
