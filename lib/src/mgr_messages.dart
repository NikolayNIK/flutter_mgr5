import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:xml/xml.dart';

/// Type for the container of frameworks localization.
typedef MgrMessages = Map<String, String>;

/// Extracts all localizations from a given xml root.
MgrMessages parseMessages(XmlElement rootElement) => {
      for (var element in rootElement
          .findElements('messages')
          .expand((element) => element.findElements('msg')))
        element.attribute('name') ?? '': element.text
    };
