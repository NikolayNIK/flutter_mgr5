import 'package:flutter/material.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/mgr_messages.dart';
import 'package:xml/xml.dart';

enum TextDataType { msg, msgdata, data }

TextDataType _typeFromString(String? value) {
  switch (value) {
    case 'msg':
      return TextDataType.msg;
    case 'msgdata':
      return TextDataType.msgdata;
    case 'data':
    case '':
    case null:
      return TextDataType.data;
    default:
      throw 'invalid value: "$value"'; // TODO exception
  }
}

abstract class TextDataFormFieldControlModel extends FormFieldControlModel {
  final bool isWarning;

  factory TextDataFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer}) {
    switch (
        element.requireConvertAttribute('type', converter: _typeFromString)) {
      case TextDataType.msg:
        return MsgTextDataFormFieldControlModel(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case TextDataType.msgdata:
        return MsgDataTextDataFormFieldControlModel(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case TextDataType.data:
        return DataTextDataFormFieldControlModel(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
    }
  }

  TextDataFormFieldControlModel._init(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : isWarning = element.boolAttribute('warning'),
        super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);

  String? resolveValue(Map<String, String?> controller);

  @override
  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    MgrExceptionHolder? exceptionHolder,
  }) =>
      MgrFormTextData(
        controller: controller,
        model: this,
        forceReadOnly: forceReadOnly,
      );
}

class MsgTextDataFormFieldControlModel extends TextDataFormFieldControlModel {
  late final String? _value;

  MsgTextDataFormFieldControlModel(
    XmlElement element, {
    required Map<String, String> messages,
    ConditionalStateCheckerConsumer? conditionalHideConsumer,
  }) : super._init(
          element,
          messages: messages,
          conditionalHideConsumer: conditionalHideConsumer,
        ) {
    _value = messages[name];
  }

  @override
  String? resolveValue(Map<String, String?> controller) => _value;
}

class MsgDataTextDataFormFieldControlModel
    extends TextDataFormFieldControlModel {
  final MgrMessages _messages;

  MsgDataTextDataFormFieldControlModel(
    XmlElement element, {
    required Map<String, String> messages,
    ConditionalStateCheckerConsumer? conditionalHideConsumer,
  })  : _messages = messages,
        super._init(
          element,
          messages: messages,
          conditionalHideConsumer: conditionalHideConsumer,
        );

  @override
  String? resolveValue(Map<String, String?> controller) =>
      _messages[controller[name] ?? ''];
}

class DataTextDataFormFieldControlModel extends TextDataFormFieldControlModel {
  DataTextDataFormFieldControlModel(
    XmlElement element, {
    required Map<String, String> messages,
    ConditionalStateCheckerConsumer? conditionalHideConsumer,
  }) : super._init(
          element,
          messages: messages,
          conditionalHideConsumer: conditionalHideConsumer,
        );

  @override
  String? resolveValue(Map<String, String?> controller) => controller[name];
}

class MgrFormTextData extends StatelessWidget {
  final MgrFormController controller;
  final TextDataFormFieldControlModel model;
  final bool forceReadOnly;

  const MgrFormTextData({
    Key? key,
    required this.controller,
    required this.model,
    this.forceReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge;
    return Text(
      model.resolveValue(controller.stringParams) ?? '',
      style: model.isWarning
          ? style?.copyWith(color: theme.colorScheme.error)
          : style,
    );
  }
}
