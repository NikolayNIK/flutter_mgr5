import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:xml/xml.dart';

abstract class MgrFormatExceptionReporter {
  void report(MgrFormatException exception);
}

class CollectorMgrFormatReporter extends MgrFormatExceptionReporter {
  final List<MgrFormatException> _list = [];

  List<MgrFormatException> get list => List.unmodifiable(_list);

  @override
  void report(MgrFormatException exception) => _list.add(exception);
}

class MgrFormatException implements Exception {
  final String message;

  MgrFormatException(this.message);

  @override
  String toString() => message;
}

class MgrMissingAttributeException extends MgrFormatException {
  MgrMissingAttributeException(String message) : super(message);
}

class MgrUnexpectedTagException extends MgrFormatException {
  MgrUnexpectedTagException(XmlElement element)
      : super('Unexpected element at ${element.positionDescription}');
}
