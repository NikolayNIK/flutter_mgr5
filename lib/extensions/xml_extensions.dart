import 'package:flutter_mgr5/src/mgr_format.dart';
import 'package:xml/xml.dart';

bool _parseBool(String? value) => value == 'yes';

extension XmlChildExtension on XmlHasChildren {
  XmlElement? child(String name, {String? namespace}) =>
      getElement(name, namespace: namespace);
}

extension XmlAttributeExtension on XmlHasAttributes {
  String? attribute(String name, {String? namespace}) =>
      getAttribute(name, namespace: namespace);

  XmlNode? attributeNode(String name, {String? namespace}) =>
      getAttributeNode(name, namespace: namespace);

  bool boolAttribute(String name, {String? namespace}) =>
      convertAttribute(name, namespace: namespace, converter: _parseBool);

  String requireAttribute(String name, {String? namespace}) {
    final attr = attribute(name, namespace: namespace);
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
      return converter(attribute(name, namespace: namespace));
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
