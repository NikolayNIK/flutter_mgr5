import 'package:flutter/material.dart';
import 'package:flutter_mgr5/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/form/mgr_form_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';

class LinkFormFieldControlModel extends FormFieldControlModel {
  final String? text;

  LinkFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : text = messages[element.name],
        super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);

  @override
  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    MgrExceptionHolder? exceptionHolder,
  }) =>
      MgrFormLink(controller: controller, model: this);
}

class MgrFormLink extends StatelessWidget {
  final MgrFormController controller;
  final LinkFormFieldControlModel model;

  const MgrFormLink({
    Key? key,
    required this.controller,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final url = controller.stringParams[model.name];
    return IntrinsicWidth(
      child: TextButton(
        onPressed: url == null ? null : () => launch(url),
        child: Text(model.text ?? url ?? ''),
      ),
    );
  }
}
