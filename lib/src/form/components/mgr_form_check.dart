import 'package:flutter/material.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:xml/xml.dart';

class CheckFormFieldControlModel extends FormFieldControlModel {
  CheckFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);

  @override
  String? extractValue(XmlElement element) {
    final value = super.extractValue(element);
    return value == null
        ? null
        : value == 'on'
            ? 'on'
            : 'off';
  }

  @override
  void updateController(MgrFormController controller) =>
      controller.params[name].checkBoxController;

  @override
  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    MgrExceptionHolder? exceptionHolder,
  }) =>
      MgrFormCheck(
        controller: controller,
        model: this,
        forceReadOnly: forceReadOnly,
      );
}

class MgrFormCheck extends StatelessWidget {
  final MgrFormController controller;
  final CheckFormFieldControlModel model;
  final bool forceReadOnly;

  const MgrFormCheck({
    Key? key,
    required this.controller,
    required this.model,
    this.forceReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = this.controller.params[model.name].checkBoxController;
    return ValueListenableBuilder<bool>(
        valueListenable: controller.container,
        builder: (context, value, child) => Align(
              alignment: Alignment.centerLeft,
              child: Checkbox(
                  focusNode: controller.focusNode,
                  value: value,
                  onChanged: forceReadOnly || model.isReadonly
                      ? null
                      : (value) => controller.container.value = value ?? false),
            ));
  }
}
