import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:xml/xml.dart';

class MgrException implements Exception {
  final String? type, object, value, message;

  MgrException(this.type, this.object, this.value, this.message);

  MgrException.fromElement(XmlElement element)
      : type = element.attribute('type'),
        object = element.attribute('object'),
        value = element.attribute('value'),
        message = element.child('msg')?.text;

  @override
  String toString() =>
      message ??
      'type "${type ?? 'null'}",'
          ' object "${object ?? 'null'}",'
          ' value "${value ?? 'null'}"';
}
