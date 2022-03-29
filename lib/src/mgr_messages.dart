import 'package:xml/xml.dart';

typedef MgrMessages = Map<String, String>;

Map<String, String> parseMessages(XmlElement rootElement) => {
      for (var element in rootElement
          .findElements('messages')
          .expand((element) => element.findElements('msg')))
        element.getAttribute('name') ?? '': element.text
    };
