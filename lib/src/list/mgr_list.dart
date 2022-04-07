import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

class MgrList extends StatelessWidget {
  final MgrListModel model;
  final MgrListController controller;

  const MgrList({
    Key? key,
    required this.model,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => controller.items.clear(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      model.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () => controller.items.clear(),
                    icon: Icon(Icons.refresh)),
              ],
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ListenableBuilder(
            listenable: controller.selection,
            builder: (context) => Row(
              children: [
                for (final toolgrp in model.toolbar) ...[
                  const SizedBox(width: 8.0),
                  for (final toolbtn in toolgrp)
                    OptionalTooltip(
                      message: toolbtn.hint,
                      child: Builder(builder: (context) {
                        final enabled = toolbtn.selectionType
                            .check(controller.selection.length);
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
                                              .withOpacity(.5),
                                    ),
                                    if (toolbtn.label != null)
                                      Text(
                                        toolbtn.label!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
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
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth - 16.0;
              final cols = [
                for (final col in model.coldata)
                  _Col(col: col, width: availableWidth / model.coldata.length),
              ];

              final rowHeight =
                  56.0 + 8.0 * Theme.of(context).visualDensity.vertical;

              return ListenableBuilder(
                listenable: controller.selection,
                builder: (context) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          for (final col in cols)
                            OptionalTooltip(
                              message: col.col.hint,
                              child: InkWell(
                                onTap: () {},
                                child: SizedBox(
                                  width: col.width,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      col.col.label ?? '',
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 2,
                      thickness: 2,
                      indent: 16.0,
                    ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: controller.items,
                        builder: (context) => ListView.builder(
                          itemCount: controller.items.length,
                          itemExtent: rowHeight,
                          itemBuilder: (context, index) {
                            final elem = controller.items[index];
                            final key = elem == null
                                ? null
                                : model.keyField == null
                                    ? null
                                    : elem[model.keyField];
                            final isSelected = key == null
                                ? false
                                : controller.selection.contains(key);
                            return ValueAnimatedSwitcher(
                              value: elem == null,
                              duration: const Duration(milliseconds: 400),
                              child: elem == null
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Center(
                                        child: Shimmer.fromColors(
                                          baseColor: Colors.transparent,
                                          highlightColor: Color(0x40808080),
                                          child: Row(
                                            children: [
                                              for (final col in cols)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0),
                                                  child: Container(
                                                    width: col.width - 8.0,
                                                    height: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.fontSize ??
                                                        16.0,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : ValueAnimatedSwitcher(
                                      value: isSelected,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Material(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : null,
                                        child: InkWell(
                                          onTap: key == null
                                              ? null
                                              : () {
                                                  if (!controller.selection
                                                      .add(key))
                                                    controller.selection
                                                        .remove(key);
                                                },
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: double.infinity,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: Row(
                                                children: [
                                                  for (final col in cols)
                                                    SizedBox(
                                                      width: col.width,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                left: 8.0),
                                                        child: Text(
                                                          elem[col.col.name] ??
                                                              '',
                                                          maxLines: 1,
                                                          softWrap: false,
                                                          overflow:
                                                              TextOverflow.fade,
                                                          style: TextStyle(
                                                              color: isSelected
                                                                  ? Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onPrimary
                                                                  : null),
                                                        ),
                                                      ),
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
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
