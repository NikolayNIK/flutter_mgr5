import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart'
    deferred as deferred_form show MgrFormModel;
import 'package:flutter_mgr5/src/list/mgr_list_model.dart'
    deferred as deferred_list show MgrListModel;
import 'package:flutter_mgr5/src/mgr_format.dart';
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

  static Future<MgrModel> fromXmlDocument(XmlDocument doc) =>
      MgrModel.fromXmlElement(doc.rootElement);

  static Future<MgrModel> fromXmlElement(XmlElement element) {
    switch (element
        .child('metadata')
        ?.requireConvertAttribute('type', converter: _typeFromString)) {
      case MgrModelType.form:
        return () async {
          await deferred_form.loadLibrary();
          return deferred_form.MgrFormModel.fromXmlElement(element);
        }();
      case MgrModelType.list:
        return () async {
          await deferred_list.loadLibrary();
          return deferred_list.MgrListModel.fromXmlElement(element);
        }();
      case MgrModelType.report:
        throw UnimplementedError('report is not implemented yet');
      default:
        throw MgrFormatException('unknown metadata type');
    }
  }

  String get title;
}
