import 'package:flutter_mgr5/form/components/mgr_form_text_data.dart';
import 'package:flutter_mgr5/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/form/mgr_form_model.dart';
import 'package:xml/xml.dart';

class DateTimeFormFieldControlModel extends DataTextDataFormFieldControlModel {
  DateTimeFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : super(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);

  @override
  void updateController(MgrFormController controller) =>
      controller.params[name].datetimeController;
}
