import 'package:flutter_mgr5/form/mgr_form_model.dart';
import 'package:xml/xml.dart';

class ListFormFieldControlModel extends FormFieldControlModel {
  ListFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
}
