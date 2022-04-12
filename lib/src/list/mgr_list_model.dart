import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/iterator_extensions.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/mgr_messages.dart';
import 'package:flutter_mgr5/src/mgr_model.dart';
import 'package:xml/xml.dart';

typedef MgrListElem = Map<String, String>;

@immutable
class MgrListModel extends MgrModel {
  final String title;
  final String? keyField, keyNameField;
  final List<MgrListCol> coldata;
  final List<List<MgrListToolbtn>> toolbar;
  final List<String> pageNames;
  final List<MgrListElem> pageData;
  final int? pageIndex;
  final int? elemCount;

  const MgrListModel({
    required String func,
    required this.title,
    required this.keyField,
    required this.keyNameField,
    required this.coldata,
    required this.toolbar,
    required this.pageNames,
    required this.pageData,
    required this.pageIndex,
    required this.elemCount,
  }) : super(func);

  factory MgrListModel.fromXmlDocument(XmlDocument doc,
          [MgrMessages? messages]) =>
      MgrListModel.fromXmlElement(doc.rootElement, messages);

  factory MgrListModel.fromXmlElement(XmlElement doc,
      [MgrMessages? mgrMessages]) {
    final messages = mgrMessages ?? parseMessages(doc);
    final metadata = doc.findElements('metadata');
    final pNum = doc.child('p_num');
    final pElems = doc.child('p_elems');
    final pageData = List<MgrListElem>.unmodifiable(doc
        .findElements('elem')
        .map((e) => Map.fromIterable(e.childElements,
            key: (element) => (element as XmlElement).name.local,
            value: (element) => (element as XmlElement).innerText)));
    return MgrListModel(
      func: doc.requireAttribute('func'),
      title: messages['title'] ?? '',
      keyField: metadata.maybeFirst?.attribute('key'),
      keyNameField: doc.attribute('keyname'),
      coldata: List.unmodifiable(
        metadata
            .expand((metadata) => metadata.findElements('coldata'))
            .expand((coldata) => coldata.findElements('col'))
            .map((col) => MgrListCol.fromXmlElement(pageData, col, messages)),
      ),
      toolbar: List<List<MgrListToolbtn>>.unmodifiable(
        metadata
            .expand((metadata) => metadata.findElements('toolbar'))
            .expand((toolbar) => toolbar.findElements('toolgrp'))
            .map((toolgrp) => List<MgrListToolbtn>.unmodifiable(toolgrp
                .findElements('toolbtn')
                .map((e) => MgrListToolbtn.fromXmlElement(e, messages)))),
      ),
      pageNames:
          List.unmodifiable(doc.findElements('page').map((e) => e.innerText)),
      pageData: pageData,
      pageIndex: pNum == null ? null : int.tryParse(pNum.innerText),
      elemCount: pElems == null ? null : int.tryParse(pElems.innerText),
    );
  }
}

@immutable
class MgrListCol {
  final String name;
  final String? label, hint;
  final double width;
  final List<MgrListColProp> props;

  const MgrListCol({
    required this.name,
    required this.label,
    required this.hint,
    required this.width,
    required this.props,
  });

  factory MgrListCol.fromXmlElement(
    List<MgrListElem> elems,
    XmlElement element,
    MgrMessages messages,
  ) {
    final name = element.requireAttribute('name');
    final label = messages[name];
    final width = element.attribute('cf_width');
    final props = List<MgrListColProp>.unmodifiable(element.childElements
        .map((e) => MgrListColProp.fromXmlElement(e, messages)));
    return MgrListCol(
      name: name,
      label: label,
      hint: messages['hint_$name'],
      width: (width == null ? null : double.tryParse(width)) ??
          _calculateWidth(
            elems,
            name,
            label,
            props,
          ),
      props: props,
    );
  }

  static double _calculateWidth(
    List<MgrListElem> elems,
    String name,
    String? label,
    List<MgrListColProp> props,
  ) {
    int maxLength = 4;

    for (final elem in elems) {
      var length = elem[name]?.length ?? 0;
      for (final prop in props) {
        if (prop.checkVisible(elem)) {
          length += 4;
        }
      }

      if (length > maxLength) {
        maxLength = length;
      }
    }

    if (label != null && label.length > maxLength) {
      maxLength = label.length;
    }

    return 16.0 + 8.0 * maxLength;
  }
}

@immutable
abstract class MgrListColProp {
  final String name;
  final IconData icon;

  MgrListColProp({required this.name, required this.icon});

  factory MgrListColProp.fromXmlElement(
      XmlElement element, MgrMessages messages) {
    switch (element.name.local) {
      case 'prop':
        return StaticMgrListColProp.fromXmlElement(element);
      case 'xprop':
        return DynamicMgrListColProp.fromXmlElement(element, messages);
      default:
        throw MgrFormatException(
            'invalid prop tag name: ${element.name.local}');
    }
  }

  bool checkVisible(MgrListElem elem);

  String? extractLabel(MgrListElem elem);
}

class StaticMgrListColProp extends MgrListColProp {
  StaticMgrListColProp({
    required String name,
    required IconData icon,
  }) : super(name: name, icon: icon);

  factory StaticMgrListColProp.fromXmlElement(XmlElement element) =>
      StaticMgrListColProp(
        name: element.requireAttribute('name'),
        icon: element.requireConvertAttribute('img',
            converter: _parseIconRequire),
      );

  @override
  bool checkVisible(MgrListElem elem) => elem.containsKey(name);

  @override
  String? extractLabel(MgrListElem elem) => elem[name];
}

class DynamicMgrListColProp extends MgrListColProp {
  final String? value;
  final MgrMessages messages;

  DynamicMgrListColProp({
    required String name,
    required IconData icon,
    required this.value,
    required this.messages,
  }) : super(name: name, icon: icon);

  factory DynamicMgrListColProp.fromXmlElement(
          XmlElement element, MgrMessages messages) =>
      DynamicMgrListColProp(
        name: element.requireAttribute('name'),
        icon: element.requireConvertAttribute('img',
            converter: _parseIconRequire),
        value: element.attribute('value'),
        messages: messages,
      );

  @override
  bool checkVisible(MgrListElem elem) =>
      elem[name] == value; // TODO value == null

  @override
  String? extractLabel(MgrListElem elem) =>
      (messages['hint_p_${name}_$value'] ??
              messages['hint_p_$name'] ??
              elem[name])
          ?.replaceAll('_value_', elem[name] ?? '');
}

IconData _parseIconRequire(String name) {
  final result = _parseIcon(name);
  if (result == null) {
    return Icons.question_mark; // TODO
    throw MgrFormatException('icon not found: "$name"');
  }

  return result;
}

IconData? _parseIcon(String name) {
  switch (name) {
    case 't-new':
      return Icons.add;
    case 't-edit':
      return Icons.edit;
    case 't-delete':
      return Icons.delete;
    case 't-download':
      return Icons.download;
    case 't-retry':
      return Icons.refresh;
    case 't-filter':
      return Icons.filter_alt;
    case 't-credit':
      return Icons.list_alt;
    case 't-editlist':
      return Icons.topic;
    case 'p-attr':
    case 't-set':
      return Icons.settings;
    case 't-contract':
      return Icons.assignment;
    case 't-verified':
      return Icons.done;
    case 't-verified2':
      return Icons.done_all;
    case 't-redirect':
      return Icons.assignment_return;
    case 't-wait':
    case 'p-wait':
      return Icons.hourglass_top;
    case 't-arrived':
    case 'p-arrived':
      return Icons.hourglass_bottom;
    case 't-setpaid':
    case 'p-setpaid':
      return Icons.paid;
    case 't-restart':
      return Icons.replay;
    case 't-undo':
      return Icons.undo;
    case 'p-lock-yellow':
    case 't-lock':
      return Icons.lock;
    case 't-unlock':
      return Icons.no_encryption;
    case 't-iplist':
      return Icons.dns;
    case 't-aid':
      return Icons.medical_services;
    case 't-rotate':
      return Icons.threesixty;
    case 'p-inetonoff':
      return Icons.lan; // TODO
    case 'p-file-100':
      return Icons.insert_drive_file;
    case 'p-time':
      return Icons.schedule;
    case 'p-contract':
      return Icons.article;
    case 'p-verified':
      return Icons.done;
    case 'p-file-99':
      return Icons.hourglass_empty;
    case 'p-accrued':
      return Icons.request_quote;
    case 'p-verified2':
      return Icons.done_all;
    case 'p-stop':
      return Icons.stop;
    case 'p-error':
      return Icons.warning;
    case 'p-nobak':
      return Icons.cloud_off;
    case 'p-note':
      return Icons.note;
    case 'p-user':
    case 't-users':
      return Icons.person;
    default:
      return null;
  }
}

enum MgrListToolbtnActivateSelectionType {
  none,
  single,
  multiple,
  any,
}

extension MgrListToolbtnActivateSelectionTypeExtension
    on MgrListToolbtnActivateSelectionType {
  static MgrListToolbtnActivateSelectionType fromXmlElement(
      XmlElement element) {
    final type = element.requireAttribute('type');
    switch (type) {
      case 'new':
      case 'back':
      case 'groupformnosel':
      case 'list':
      case 'refresh':
      case 'windownosel':
      case 'url':
        return MgrListToolbtnActivateSelectionType.any;
      case 'editnosel':
        return MgrListToolbtnActivateSelectionType.any;
      case 'action':
      case 'editlist':
      case 'window':
      case 'preview':
        return MgrListToolbtnActivateSelectionType.single;
      case 'edit':
        return element.boolAttribute('nogroupedit')
            ? MgrListToolbtnActivateSelectionType.single
            : MgrListToolbtnActivateSelectionType.multiple;
      case 'group':
      case 'groupdownload':
      case 'groupform':
      case 'groupwindow':
        return MgrListToolbtnActivateSelectionType.multiple;
      default:
        throw MgrFormatException('unknown type: "$type"');
    }
  }

  bool check(int selectionCount) {
    switch (this) {
      case MgrListToolbtnActivateSelectionType.none:
        return selectionCount == 0;
      case MgrListToolbtnActivateSelectionType.single:
        return selectionCount == 1;
      case MgrListToolbtnActivateSelectionType.multiple:
        return selectionCount > 0;
      case MgrListToolbtnActivateSelectionType.any:
        return true;
    }
  }
}

@immutable
class MgrListToolbtn {
  final String name;
  final String? label, hint;
  final IconData? icon;
  final MgrListToolbtnActivateSelectionType selectionType;

  const MgrListToolbtn({
    required this.name,
    required this.label,
    required this.hint,
    required this.icon,
    required this.selectionType,
  });

  factory MgrListToolbtn.fromXmlElement(
      XmlElement element, MgrMessages messages) {
    final name = element.requireAttribute('name');
    return MgrListToolbtn(
      name: element.requireAttribute('name'),
      label: messages['short_$name'],
      hint: messages['hint_$name'],
      icon: element.requireConvertAttribute('img', converter: _parseIcon),
      selectionType:
          MgrListToolbtnActivateSelectionTypeExtension.fromXmlElement(element),
    );
  }
}
