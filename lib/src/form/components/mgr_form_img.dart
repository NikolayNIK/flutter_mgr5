import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:xml/xml.dart';

class ImgFormFieldControlModel extends FormFieldControlModel {
  ImgFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
}