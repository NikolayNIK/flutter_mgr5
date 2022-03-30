import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:xml/xml.dart';

class HtmlDataFormFieldControlModel extends FormFieldControlModel {
  final double? height;
  final String? chheight;

  HtmlDataFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : height = element.convertAttribute(
          'height',
          converter: (value) => value == null ? null : double.tryParse(value),
        ),
        chheight = element.attribute('chheight'),
        super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);

  @override
  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    MgrExceptionHolder? exceptionHolder,
  }) =>
      MgrFormHtmlData(
        controller: controller,
        model: this,
      );
}

class MgrFormHtmlData extends StatelessWidget {
  final MgrFormController controller;
  final HtmlDataFormFieldControlModel model;

  const MgrFormHtmlData(
      {Key? key, required this.controller, required this.model})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = controller.stringParams[model.name];
    if (data == null) {
      return const SizedBox();
    }

    final height = model.chheight != null
        ? double.tryParse(controller.stringParams[model.chheight!] ?? 'kostil')
        : model.height;
    final content = Html(
      data: data,
      shrinkWrap: true,
    );

    return model.height == null
        ? content
        : SizedBox(
            height: height,
            child: content,
          );
  }
}
