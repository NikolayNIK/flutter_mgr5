import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:xml/xml.dart';

enum ListFormFieldColType {
  data,
}

enum ListFormFieldType {
  table,
  block;

  static ListFormFieldType fromString(String? value) =>
      value == 'table' ? table : block;
}

@immutable
class ListFormFieldCol extends TableColumn {
  final String name;
  final String label;

  const ListFormFieldCol({
    required this.name,
    required this.label,
    required super.width,
    super.freezePriority,
    int flex = 1,
  }) : super(flex: flex);

  factory ListFormFieldCol.fromXmlElement(
    XmlElement element, {
    required Map<String, String> messages,
  }) {
    final name = element.requireAttribute('name');
    final width = element.getAttribute('cf_width');
    const double defaultWidth = 128;
    final freezePriority = element.getAttribute('cf_freeze');
    return ListFormFieldCol(
      name: name,
      label: messages['list_$name'] ?? '',
      width:
          width == null ? defaultWidth : double.tryParse(width) ?? defaultWidth,
      freezePriority:
          freezePriority == null ? 0 : int.tryParse(freezePriority) ?? 0,
    );
  }
}

class ListFormFieldControlModel extends FormFieldControlModel {
  final ListFormFieldType type;
  final List<ListFormFieldCol> coldata;

  ListFormFieldControlModel.fromXmlElement(
    XmlElement element, {
    required Map<String, String> messages,
    ConditionalStateCheckerConsumer? conditionalHideConsumer,
  })  : type = element.convertAttribute('type',
            converter: ListFormFieldType.fromString),
        coldata = element
            .findElements('col')
            .map((e) => ListFormFieldCol.fromXmlElement(e, messages: messages))
            .toList(),
        super.innerFromXmlElement(
          element,
          messages: messages,
          conditionalHideConsumer: conditionalHideConsumer,
        );

  @override
  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    required MgrExceptionHolder? exceptionHolder,
  }) =>
      MgrFormList(
        model: this,
        controller: controller,
        forceReadOnly: forceReadOnly,
      );
}

class MgrFormList extends StatefulWidget {
  final MgrFormController controller;
  final ListFormFieldControlModel model;
  final bool forceReadOnly;

  const MgrFormList({
    required this.controller,
    required this.model,
    required this.forceReadOnly,
  });

  @override
  State<MgrFormList> createState() => _MgrFormListState();
}

class _MgrFormListState extends State<MgrFormList> {
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<MgrFormListContent>(
        valueListenable: widget.controller.lists[widget.model.name],
        builder: (context, list, _) {
          const itemHeight = 36.0;
          return SizedBox(
            width: double.infinity,
            height: (list.length + 1) * itemHeight + 8,
            child: TableView.builder(
              rowCount: list.length,
              rowHeight: itemHeight,
              style: const TableViewStyle(
                dividers: TableViewDividersStyle(
                  vertical: TableViewVerticalDividersStyle.symmetric(
                    TableViewVerticalDividerStyle(
                      wiggleOffset: 6,
                      wigglesPerRow: 3,
                    ),
                  ),
                ),
                scrollbars: TableViewScrollbarsStyle(
                  horizontal: TableViewScrollbarStyle(
                    scrollPadding: false,
                    thumbVisibility: WidgetStatePropertyAll(true),
                  ),
                  vertical: TableViewScrollbarStyle.disabled(),
                ),
              ),
              columns: widget.model.coldata,
              headerBuilder: widget.model.type != ListFormFieldType.table
                  ? null
                  : (context, contentBuilder) => contentBuilder(
                        context,
                        (context, column) => Padding(
                          padding: column == 0
                              ? EdgeInsets.zero
                              : const EdgeInsets.only(left: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.model.coldata[column].label,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ),
                      ),
              rowBuilder: (context, row, contentBuilder) {
                final elem = list[row];
                return contentBuilder(
                  context,
                  (context, column) => Padding(
                    padding: column == 0
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(left: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        elem[widget.model.coldata[column].name] ?? '',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}
