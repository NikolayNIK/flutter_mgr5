import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/list/mgr_list_model.dart';
import 'package:xml/xml.dart';

/// Type of MgrModel.
enum MgrModelType {
  form,
  list,
  report,
}

MgrModelType _typeFromString(String type) {
  switch (type) {
    case 'form':
      return MgrModelType.form;
    case 'list':
      return MgrModelType.list;
    case 'report':
      return MgrModelType.report;
    default:
      throw 'invalid type value: "$type"'; // TODO
  }
}

/// Immutable model of a frameworks entity containing all the information
/// needed to display form, list or report.
@immutable
abstract class MgrModel {
  final String func;

  const MgrModel(this.func);

  factory MgrModel.fromXmlDocument(XmlDocument doc) =>
      MgrModel.fromXmlElement(doc.rootElement);

  factory MgrModel.fromXmlElement(XmlElement element) {
    switch (
        element.child('metadata')?.requireConvertAttribute('type', converter: _typeFromString)) {
      case MgrModelType.form:
        return MgrFormModel.fromXmlElement(element);
      case MgrModelType.list:
        return MgrListModel.fromXmlElement(element);
      case MgrModelType.report:
        throw UnimplementedError('report is not implemented yet');
      default:
        throw MgrFormatException('unknown metadata type');
    }
  }

  String get title;
}
