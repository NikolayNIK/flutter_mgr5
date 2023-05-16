import 'package:flutter/material.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';
import 'package:xml/xml.dart';

class TextAreaFormFieldControlModel extends FormFieldControlModel {
  final int rows;

  TextAreaFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : rows = int.parse(element.attribute('rows') ?? '1'),
        super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);

  @override
  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    MgrExceptionHolder? exceptionHolder,
  }) =>
      MgrFormTextArea(
        controller: controller,
        model: this,
        forceReadOnly: forceReadOnly,
        exception: exceptionHolder?.consume(),
      );
}

class MgrFormTextArea extends StatelessWidget {
  final MgrFormController controller;
  final TextAreaFormFieldControlModel model;
  final MgrException? exception;
  final bool forceReadOnly;

  const MgrFormTextArea({
    Key? key,
    required this.controller,
    required this.model,
    this.forceReadOnly = false,
    this.exception,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = this.controller.params[model.name].textInputController;
    final textEditingController = controller.textEditingController;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ListenableBuilder(
        listenable: textEditingController,
        builder: (context, _) => TextField(
          focusNode: controller.focusNode,
          controller: textEditingController,
          readOnly: forceReadOnly || model.isReadonly,
          decoration: InputDecoration(
            filled: true,
            errorMaxLines: 16,
            errorText: controller.isChanged ? null : exception?.toString(),
          ),
          style: !forceReadOnly && !model.isReadonly
              ? null
              : theme.textTheme.subtitle1?.copyWith(
                  color: theme.disabledColor,
                ),
          minLines: model.rows,
          maxLines: model.rows,
        ),
      ),
    );
  }
}
