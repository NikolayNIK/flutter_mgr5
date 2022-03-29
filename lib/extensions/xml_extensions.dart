import 'package:flutter_mgr5/src/mgr_format.dart';
import 'package:xml/xml.dart';

extension XmlAttributeExtension on XmlHasAttributes {
  bool getAttributeBool(String name, {String? namespace}) =>
      getAttribute(name, namespace: namespace) == 'yes';

  String requireAttribute(String name, {String? namespace}) {
    final attr = getAttribute(name, namespace: namespace);
    if (attr == null) {
      throw MgrMissingAttributeException('Missing required attribute "$name"' +
          (this is XmlElement
              ? ' in ${(this as XmlElement).positionDescription}'
              : ''));
    }

    return attr;
  }

  T convertAttribute<T>(String name,
      {String? namespace, required T Function(String? value) converter}) {
    try {
      return converter(getAttribute(name, namespace: namespace));
    } on MgrFormatException catch (exception) {
      throw MgrFormatException('Invalid value of attribute "$name"' +
          (this is XmlElement
              ? ' in ${(this as XmlElement).positionDescription}'
              : '') +
          ': ${exception.toString()}'); // TODO
    }
  }

  T requireConvertAttribute<T>(String name,
      {String? namespace, required T Function(String value) converter}) {
    final attr = requireAttribute(name, namespace: namespace);
    try {
      return converter(attr);
    } on MgrFormatException catch (exception) {
      throw MgrFormatException('Invalid value of attribute "$name"' +
          (this is XmlElement
              ? ' in ${(this as XmlElement).positionDescription}'
              : '') +
          ': ${exception.toString()}'); // TODO
    }
  }
}

extension XmlPositionDescriptionExtension on XmlElement {
  String get positionDescription {
    if (parent == document) {
      return '/${name.local}';
    }

    final parentElement = this.parentElement;
    if (parentElement != null) {
      int? indexInParent;
      int i = 0;
      bool hasSiblingsWithSameName = false;
      for (final child in parentElement.childElements) {
        i++;

        if (identical(child, this)) {
          indexInParent = i;
          if (hasSiblingsWithSameName) {
            break;
          }
        } else if (child.name.local == name.local) {
          hasSiblingsWithSameName = true;
          if (indexInParent != null) {
            break;
          }
        }
      }

      return hasSiblingsWithSameName && indexInParent != null
          ? '${parentElement.positionDescription}/${name.local}[$indexInParent]'
          : '${parentElement.positionDescription}/${name.local}';
    }

    return name.local;
  }
}
