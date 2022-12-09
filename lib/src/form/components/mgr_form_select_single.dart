import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mgr5/listenable_builder.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/form/slist.dart';

typedef MgrFormSelectSingleItemBuilder = Widget Function(
  BuildContext context,
  SlistEntry entry,
);

typedef MgrFormSelectSingleOnChanged = void Function(SlistEntry index);

class MgrFormSelectSingle extends StatefulWidget {
  final MgrSingleSelectController controller;
  final double itemHeight;
  final MgrFormSelectSingleItemBuilder itemBuilder;
  final FocusNode? focusNode;
  final MgrFormSelectSingleOnChanged? onChanged;
  final BorderRadius borderRadius;

  const MgrFormSelectSingle({
    super.key,
    required this.controller,
    required this.itemHeight,
    required this.itemBuilder,
    required this.onChanged,
    this.borderRadius = const BorderRadius.all(Radius.circular(2.0)),
    this.focusNode,
  });

  @override
  State<MgrFormSelectSingle> createState() => _MgrFormSelectSingleState();
}

class _MgrFormSelectSingleState extends State<MgrFormSelectSingle> {
  bool get enabled => widget.onChanged != null;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          focusNode: widget.focusNode,
          borderRadius: widget.borderRadius,
          onTap: enabled ? _onTap : null,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: widget.itemHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: widget.controller,
                          builder: (context) => _buildItem(
                            context,
                            widget.controller.slist
                                .value[widget.controller.valueIndex],
                          ),
                        ),
                      ),
                      Icon(
                        color: enabled ? null : Theme.of(context).disabledColor,
                        Icons.arrow_drop_down,
                      ),
                    ],
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

  Widget _buildItem(BuildContext context, SlistEntry entry) {
    final textStyle = Theme.of(context).textTheme.subtitle1!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DefaultTextStyle(
          style: enabled
              ? textStyle
              : textStyle.copyWith(color: Theme.of(context).disabledColor),
          child: Builder(
              builder: (context) => widget.itemBuilder(context, entry))),
    );
  }

  void _onTap() {
    final navigator = Navigator.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final rect = renderBox.localToGlobal(Offset.zero,
            ancestor: navigator.context.findRenderObject()) &
        renderBox.size;

    navigator
        .push(_DropdownRoute(
      controller: widget.controller,
      buttonRect: rect,
      itemHeight: widget.itemHeight,
      itemBuilder: _buildItem,
    ))
        .then((value) {
      if (value != null) widget.onChanged?.call(value);
    });
  }
}

class _DropdownRoute extends PopupRoute<SlistEntry> {
  final Rect buttonRect;
  final double itemHeight;
  final MgrSingleSelectController _controller;
  final MgrFormSelectSingleItemBuilder itemBuilder;

  _DropdownRoute({
    required this.buttonRect,
    required MgrSingleSelectController controller,
    required this.itemHeight,
    required this.itemBuilder,
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
      );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);
}

class _DropdownPage extends StatefulWidget {
  final Animation<double> animation;
  final Rect buttonRect;
  final double itemHeight;
  final MgrSingleSelectController controller;
  final MgrFormSelectSingleItemBuilder itemBuilder;

  const _DropdownPage({
    required this.animation,
    required this.buttonRect,
    required this.controller,
    required this.itemHeight,
    required this.itemBuilder,
  });

  @override
  State<_DropdownPage> createState() => _DropdownPageState();
}

class _DropdownPageState extends State<_DropdownPage> {
  final searchController = TextEditingController();
  final focusSearch = FocusNode();
  ScrollController? scrollController;
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context) => ListenableBuilder(
          listenable: widget.controller.slist,
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              // TODO улучшить расчет максимальной ширины элемента);
              var rect = Rect.fromLTWH(
                  widget.buttonRect.left - 48.0,
                  widget.buttonRect.top,
                  min(
                      constraints.maxWidth - 16.0 - widget.buttonRect.left,
                      max(widget.buttonRect.width + 48.0,
                          widget.controller.longestLabelLength * 11.0)),
                  min(
                      constraints.maxHeight - 16.0 - widget.buttonRect.top,
                      ((searchEnabled ? 1 : 0) + entries.length) *
                          widget.itemHeight));

              if (rect.height < widget.itemHeight * min(entries.length, 5.5)) {
                final offsetY =
                    widget.itemHeight * min(entries.length, 5.5) - rect.height;
                rect = Rect.fromLTRB(
                  rect.left,
                  max(16.0, rect.top - offsetY),
                  rect.right,
                  rect.bottom,
                );
              }

              scrollController ??= ScrollController(
                  initialScrollOffset: min(
                      ((searchEnabled ? 1 : 0) + entries.length) *
                              widget.itemHeight -
                          rect.height,
                      widget.controller.valueIndex * widget.itemHeight));

              return AnimatedBuilder(
                animation: widget.animation,
                builder: (context, child) {
                  final animationTransformed =
                      Curves.fastOutSlowIn.transform(widget.animation.value);
                  return Opacity(
                    opacity: animationTransformed,
                    child: Stack(
                      children: [
                        Positioned(
                          left: rect.left,
                          top: rect.top,
                          width: rect.width,
                          height: widget.itemHeight +
                              (rect.height - widget.itemHeight) *
                                  animationTransformed,
                          child: Material(
                            elevation: 8.0,
                            type: MaterialType.card,
                            shadowColor: Colors.black,
                            clipBehavior: Clip.hardEdge,
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              minWidth: rect.width,
                              maxWidth: rect.width,
                              minHeight: rect.height,
                              maxHeight: rect.height,
                              child: Column(
                                children: [
                                  if (searchEnabled)
                                    SizedBox(
                                      height: widget.itemHeight,
                                      child: _buildSearch(context),
                                    ),
                                  Flexible(
                                    child: Material(
                                      child: ListView.builder(
                                        controller: scrollController,
                                        shrinkWrap: true,
                                        itemExtent: widget.itemHeight,
                                        itemCount: entries.length,
                                        itemBuilder: (context, index) =>
                                            _buildItem(context, entries[index]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

  Widget _buildSearch(BuildContext context) => Stack(
        children: [
          const SizedBox(
            width: 48.0,
            child: Center(
              child: Icon(Icons.search_rounded),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 48.0,
            child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: entries.length != 1
                    ? null
                    : const Center(
                        child: Icon(Icons.keyboard_arrow_right_rounded))),
          ),
          TextField(
            focusNode: focusSearch,
            controller: searchController,
            maxLines: 1,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.only(
                left: 48.0 + 8.0,
                right: 8.0,
              ),
            ),
            textInputAction: entries.length == 1
                ? TextInputAction.send
                : TextInputAction.none,
            onSubmitted: (value) {
              if (entries.length == 1) _onTap(context, entries.single);
            },
          ),
        ],
      );

  Widget _buildItem(BuildContext context, SlistEntry entry) {
    final selected = entry.key == widget.controller.value;

    Widget result = InkWell(
      onTap: () => _onTap(context, entry),
      child: Row(
        children: [
          SizedBox(
            width: 48.0,
            height: 48.0,
            child: Center(
              child: Radio<bool>(
                value: selected,
                groupValue: true,
                onChanged: (value) => _onTap(context, entry),
              ),
            ),
          ),
          Expanded(
            child: widget.itemBuilder(context, entry),
          ),
        ],
      ),
    );

    if (selected) {
      result = ColoredBox(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(.5),
        child: result,
      );
    }

    return KeyedSubtree(
      key: ValueKey<String?>(entry.key),
      child: result,
    );
  }

  void _onTap(BuildContext context, SlistEntry entry) =>
      Navigator.pop(context, entry);
}
