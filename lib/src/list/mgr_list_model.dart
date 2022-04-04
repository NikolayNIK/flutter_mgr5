import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/iterator_extensions.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/mgr_messages.dart';
import 'package:flutter_mgr5/src/mgr_model.dart';
import 'package:xml/xml.dart';

typedef MgrListElem = Map<String, String>;

MgrListElem parseElem(XmlElement elem) => Map.fromIterable(elem.childElements,
    key: (element) => (element as XmlElement).name.local,
    value: (element) => (element as XmlElement).innerText);

@immutable
class MgrListModel extends MgrModel {
  final String title;
  final String? keyField, keyNameField;
  final List<MgrListCol> coldata;
  final List<List<MgrListToolbtn>> toolbar;

  const MgrListModel({
    required String func,
    required this.title,
    required this.keyField,
    required this.keyNameField,
    required this.coldata,
    required this.toolbar,
  }) : super(func);

  factory MgrListModel.fromXmlDocument(XmlDocument doc,
          [MgrMessages? messages]) =>
      MgrListModel.fromXmlElement(doc.rootElement, messages);

  factory MgrListModel.fromXmlElement(XmlElement doc,
      [MgrMessages? mgrMessages]) {
    final messages = mgrMessages ?? parseMessages(doc);
    final metadata = doc.findElements('metadata');
    return MgrListModel(
      func: doc.requireAttribute('func'),
      title: messages['title'] ?? '',
      keyField: metadata.maybeFirst?.attribute('key'),
      keyNameField: doc.attribute('keyname'),
      coldata: List.unmodifiable(
        metadata
            .expand((metadata) => metadata.findElements('coldata'))
            .expand((coldata) => coldata.findElements('col'))
            .map((col) => MgrListCol.fromXmlElement(col, messages)),
      ),
      toolbar: List<List<MgrListToolbtn>>.unmodifiable(
        metadata
            .expand((metadata) => metadata.findElements('toolbar'))
            .expand((toolbar) => toolbar.findElements('toolgrp'))
            .map((toolgrp) => List<MgrListToolbtn>.unmodifiable(toolgrp
                .findElements('toolbtn')
                .map((e) => MgrListToolbtn.fromXmlElement(e, messages)))),
      ),
    );
  }
}

@immutable
class MgrListCol {
  final String name;
  final String? label, hint;

  MgrListCol({
    required this.name,
    required this.label,
    required this.hint,
  });

  factory MgrListCol.fromXmlElement(XmlElement element, MgrMessages messages) {
    final name = element.requireAttribute('name');
    return MgrListCol(
      name: name,
      label: messages[name],
      hint: messages['hint_$name'],
    );
  }
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
    default:
      return null;
  }
}

@immutable
class MgrListToolbtn {
  final String name;
  final String? label, hint;
  final IconData? icon;

  const MgrListToolbtn({
    required this.name,
    required this.label,
    required this.hint,
    required this.icon,
  });

  factory MgrListToolbtn.fromXmlElement(
      XmlElement element, MgrMessages messages) {
    final name = element.requireAttribute('name');
    return MgrListToolbtn(
      name: element.requireAttribute('name'),
      label: messages['short_$name'],
      hint: messages['hint_$name'],
      icon: element.requireConvertAttribute('img', converter: _parseIcon),
    );
  }
}
