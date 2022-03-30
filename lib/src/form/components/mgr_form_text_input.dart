import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mgr5/extensions/datetime_extensions.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/listenable_builder.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:xml/xml.dart';

class TextInputFormFieldControlModel extends FormFieldControlModel {
  final String type; // TODO
  late final String? placeholder;
  late final List<TextInputFormatter> inputFormatters;
  final bool isDate;

  TextInputFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : type = element.requireAttribute('type'),
        isDate = element.boolAttribute('date'),
        super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer) {
    final mask = element.attribute('mask');
    placeholder = messages['placeholder_$name'] ??
        mask?.replaceAll(RegExp(r'[0-9]'), '_');
    inputFormatters = List.unmodifiable([
      if (mask != null)
        MaskTextInputFormatter(
          mask: mask,
          filter: {
            for (var i = 0; i < 10; i++) '$i': RegExp(r'[0-9]'),
          },
        ),
    ]);
  }

  @override
  bool get isHidden => type == 'hidden';

  @override
  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    MgrExceptionHolder? exceptionHolder,
  }) =>
      MgrFormTextInput(
        controller: controller,
        model: this,
        forceReadOnly: forceReadOnly,
        exception: exceptionHolder?.consume(),
      );
}

class MgrFormTextInput extends StatelessWidget {
  final MgrFormController controller;
  final TextInputFormFieldControlModel model;
  final MgrException? exception;
  final bool forceReadOnly;

  const MgrFormTextInput({
    Key? key,
    required this.controller,
    required this.model,
    this.forceReadOnly = false,
    this.exception,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final param = this.controller.params[model.name];
    final controller = param.textInputController;
    final textEditingController = controller.textEditingController;
    return ListenableBuilder(
      listenable: textEditingController,
      builder: (context) => Stack(
        children: [
          TextField(
            focusNode: controller.focusNode,
            controller: textEditingController,
            readOnly: forceReadOnly || model.isReadonly,
            inputFormatters: model.inputFormatters,
            decoration: InputDecoration(
              errorMaxLines: 16,
              errorText: controller.isChanged ? null : exception?.toString(),
              hintText: model.placeholder,
            ),
            style: !forceReadOnly && !model.isReadonly
                ? null
                : theme.textTheme.subtitle1?.copyWith(
                    color: theme.disabledColor,
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (model.isDate)
                IconButton(
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(controller.value) ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    ).then((value) {
                      if (value != null) {
                        param.value = value.toStringDate();
                      }
                    });
                  },
                  icon: const Icon(Icons.calendar_today),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
