import 'package:xml/xml.dart';

class MgrException implements Exception {
  final String? type, object, value, message;

  MgrException(this.type, this.object, this.value, this.message);

  MgrException.fromElement(XmlElement element)
      : type = element.getAttribute('type'),
        object = element.getAttribute('object'),
        value = element.getAttribute('value'),
        message = element.getElement('msg')?.text;

  @override
  String toString() =>
      message ??
      'type "${type ?? 'null'}",'
          ' object "${object ?? 'null'}",'
          ' value "${value ?? 'null'}"';
}
