import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart' deferred as deferred_html
    show Html;
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

class MgrFormHtmlData extends StatefulWidget {
  final MgrFormController controller;
  final HtmlDataFormFieldControlModel model;

  const MgrFormHtmlData(
      {Key? key, required this.controller, required this.model})
      : super(key: key);

  @override
  State<MgrFormHtmlData> createState() => _MgrFormHtmlDataState();
}

class _MgrFormHtmlDataState extends State<MgrFormHtmlData> {
  final future = deferred_html.loadLibrary();

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.stringParams[widget.model.name];
    if (data == null) {
      return const SizedBox();
    }

    final height = widget.model.chheight != null
        ? double.tryParse(
            widget.controller.stringParams[widget.model.chheight!] ?? 'kostil')
        : widget.model.height;
    final content = FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.done
              ? deferred_html.Html(
                  data: data,
                  shrinkWrap: true,
                )
              : const Center(child: CircularProgressIndicator()),
    );

    return widget.model.height == null
        ? content
        : SizedBox(
            height: height,
            child: content,
          );
  }
}
