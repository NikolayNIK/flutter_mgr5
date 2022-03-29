import 'package:flutter_mgr5/form/mgr_form_model.dart';
import 'package:flutter_mgr5/xml_extensions.dart';
import 'package:xml/xml.dart';

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

abstract class MgrModel {
  final String func;

  MgrModel(this.func);

  factory MgrModel.fromXmlDocument(XmlDocument doc) =>
      MgrModel.fromXmlElement(doc.rootElement);

  factory MgrModel.fromXmlElement(XmlElement element) {
    switch (
        element.requireConvertAttribute('type', converter: _typeFromString)) {
      case MgrModelType.form:
        return MgrFormModel.fromXmlElement(element);
      case MgrModelType.list:
        throw UnimplementedError('list is not implemented yet');
      case MgrModelType.report:
        throw UnimplementedError('report is not implemented yet');
    }
  }

  String get title;
}
