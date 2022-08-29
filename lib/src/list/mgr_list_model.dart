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
  final String keyField, keyNameField;
  final List<MgrListCol> coldata;
  final List<MgrListToolgrp> toolbar;
  final List<String> pageNames;
  final List<MgrListElem> pageData;
  final String? filterMessage;
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
    required this.filterMessage,
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
    final keyField = metadata.maybeFirst?.attribute('key') ?? 'id';
    final keynameField = metadata.maybeFirst?.attribute('keyname') ?? keyField;
    return MgrListModel(
      func: doc.requireAttribute('func'),
      title: messages['title'] ?? '',
      keyField: keyField,
      keyNameField: keynameField,
      coldata: List.unmodifiable(
        metadata
            .expand((metadata) => metadata.findElements('coldata'))
            .expand((coldata) => coldata.findElements('col'))
            .map((col) => MgrListCol.fromXmlElement(pageData, col, messages)),
      ),
      toolbar: List<MgrListToolgrp>.unmodifiable(metadata
          .expand((metadata) => metadata.findElements('toolbar'))
          .expand((toolbar) => toolbar.findElements('toolgrp'))
          .map((element) =>
              MgrListToolgrp.fromXmlElement(keynameField, element, messages))),
      pageNames:
          List.unmodifiable(doc.findElements('page').map((e) => e.innerText)),
      pageData: pageData,
      pageIndex: pNum == null ? null : int.tryParse(pNum.innerText),
      elemCount: pElems == null ? null : int.tryParse(pElems.innerText),
      filterMessage: doc.findElements('p_filter').fold(
          null,
          (previousValue, element) => previousValue == null
              ? element.innerText
              : '$previousValue\n${element.innerText}'),
    );
  }
}

@immutable
class MgrListCol {
  final String name;
  final String? label, hint;
  final double width;
  final MgrListColTotal? total;
  final List<MgrListColProp> props;
  final MgrListColSorted? sorted;
  final TextAlign textAlign;
  final Alignment alignment;
  final MainAxisAlignment mainAxisAlignment;

  const MgrListCol({
    required this.name,
    required this.label,
    required this.hint,
    required this.sorted,
    required this.width,
    required this.total,
    required this.props,
    required this.textAlign,
    required this.alignment,
    required this.mainAxisAlignment,
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
    final textAlign = element.convertAttribute('align', converter: _parseAlign);
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
      sorted: element.convertAttribute('sorted',
          converter: MgrListColSorted.fromXmlAttribute),
      total: element.boolAttribute('stat') || element.attribute('total') != null
          ? MgrListColTotal.sum
          : null,
      props: props,
      textAlign: textAlign,
      alignment: _alignmentFromText(textAlign),
      mainAxisAlignment: _mainAxisAlignmentFromText(textAlign),
    );
  }

  static Alignment _alignmentFromText(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.justify:
        return Alignment.center;
    }
  }

  static MainAxisAlignment _mainAxisAlignmentFromText(TextAlign textAlign) {
    switch(textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return MainAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return MainAxisAlignment.end;
      case TextAlign.center:
        return MainAxisAlignment.center;
      case TextAlign.justify:
        return MainAxisAlignment.spaceBetween;
    }
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
          length += 3;
        }
      }

      if (length > maxLength) {
        maxLength = length;
      }
    }

    if (label != null && label.length > maxLength) {
      maxLength = label.length;
    }

    return 16.0 + 16.0 * (maxLength / 2.0).ceilToDouble();
  }
}

TextAlign _parseAlign(String? value) {
  switch (value) {
    case null:
    case 'left':
      return TextAlign.start;
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.end;
    default:
      throw MgrFormatException('unknown align: "$value"');
  }
}

enum MgrListColTotal {
  sum,
  sumRound,
  average,
}

@immutable
class MgrListColSorted {
  final int index;
  final bool ascending;

  const MgrListColSorted(this.index, this.ascending);

  static MgrListColSorted? fromXmlAttribute(String? value) {
    if (value == null) {
      return null;
    }

    final bool ascending;
    final first = value[0];
    switch (first) {
      case '+':
        ascending = true;
        break;
      case '-':
        ascending = false;
        break;
      default:
        throw MgrFormatException('invalid sorted sign: $first');
    }

    return MgrListColSorted(int.parse(value.substring(1)), ascending);
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

IconData? _parseIconOrNull(String? name) =>
    name == null ? null : _parseIcon(name);

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
    case 't-back':
      return Icons.arrow_back;
    case 't-barcode':
      return Icons.qr_code;
    case 't-new-barcode':
      return Icons.qr_code_scanner;
    case 'p-print':
    case 't-print':
    case 't-printd':
    case 't-printenvelope':
      return Icons.print;
    default:
      return null;
  }
}

class MgrListToolgrp {
  final String? name;
  final IconData? img;
  final List<MgrListToolbtn> buttons;

  MgrListToolgrp({this.name, this.img, required this.buttons});

  factory MgrListToolgrp.fromXmlElement(
    String keynameField,
    XmlElement element,
    MgrMessages messages,
  ) =>
      MgrListToolgrp(
          name: element.attribute('name'),
          img: element.convertAttribute('img', converter: _parseIconOrNull),
          buttons: List<MgrListToolbtn>.unmodifiable(element
              .findElements('toolbtn')
              .map((e) =>
                  MgrListToolbtn.fromXmlElement(keynameField, e, messages))));
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

enum MgrListToolbtnState {
  shown,
  disabled,
  hidden,
}

typedef MgrListToolbtnElemStateChecker = MgrListToolbtnState Function(
  MgrListElem elem,
);

typedef MgrListToolbtnSelectionStateChecker = MgrListToolbtnState Function(
  Iterable<MgrListElem?> selection,
);

@immutable
class MgrListToolbtn {
  final String name, func;
  final String? label, hint;
  final IconData? icon;
  final MgrListToolbtnActivateSelectionType selectionType;
  final MgrListToolbtnElemStateChecker elemStateChecker;
  final MgrListToolbtnSelectionStateChecker selectionStateChecker;
  final bool confirmationRequired;
  final String? Function(Iterable<MgrListElem?> elems)?
      confirmationMessageBuilder;

  const MgrListToolbtn({
    required this.name,
    required this.func,
    required this.label,
    required this.hint,
    required this.icon,
    required this.selectionType,
    required this.elemStateChecker,
    required this.selectionStateChecker,
    required this.confirmationRequired,
    required this.confirmationMessageBuilder,
  });

  factory MgrListToolbtn.fromXmlElement(
    final String keynameField,
    XmlElement element,
    MgrMessages messages,
  ) {
    final name = element.requireAttribute('name');
    final MgrListToolbtnState defaultState =
        element.childElements.any((element) => element.name.local == 'show')
            ? MgrListToolbtnState.disabled
            : MgrListToolbtnState.shown;

    MgrListToolbtnElemStateChecker stateChecker = (elem) => defaultState;
    for (final condition in element.childElements) {
      final previous = stateChecker;
      final name = condition.attribute('name');
      final value = condition.attribute('value');
      final MgrListToolbtnState targetState;
      switch (condition.name.local) {
        case 'hide':
          targetState = MgrListToolbtnState.disabled;
          break;
        case 'show':
          targetState = MgrListToolbtnState.shown;
          break;
        case 'remove':
          targetState = MgrListToolbtnState.hidden;
          break;
        default:
          throw MgrFormatException(
              'Invalid child name ${condition.positionDescription}');
      }

      stateChecker = name == null || value == null
          ? (elem) => targetState
          : (elem) {
              if (elem[name] == value) {
                return targetState;
              }

              return previous(elem);
            };
    }

    final finalStateChecker = stateChecker;
    final selectionType =
        MgrListToolbtnActivateSelectionTypeExtension.fromXmlElement(element);
    final confirmationRequired = {
      'group',
      'groupdownload',
    }.contains(element.requireAttribute('type'));

    final confirmationMessage = messages['msg_confirm_$name'];
    final confirmationDelimiter =
        '${messages['msg_confirm_delimiter'] ?? ','}\n';
    final confirmationMessageBuilder = confirmationRequired
        ? (Iterable<MgrListElem?> elems) =>
            '$confirmationMessage\n${elems.whereNotNull().map((e) => e[keynameField]).join(confirmationDelimiter)}?'
        : null;

    return MgrListToolbtn(
      name: name,
      func: element.requireAttribute('func'),
      label: messages['short_$name'],
      hint: messages['hint_$name'],
      icon: element.requireConvertAttribute('img', converter: _parseIcon),
      selectionType: selectionType,
      elemStateChecker: finalStateChecker,
      selectionStateChecker: (selection) {
        if (selectionType.check(selection.length)) {
          MgrListToolbtnState? state;
          for (final elem in selection.whereNotNull()) {
            state = finalStateChecker(elem);
            if (state == MgrListToolbtnState.shown) {
              return state;
            }
          }

          return state ?? MgrListToolbtnState.shown;
        } else {
          return MgrListToolbtnState.disabled;
        }
      },
      confirmationRequired: confirmationRequired,
      confirmationMessageBuilder: confirmationMessageBuilder,
    );
  }
}
