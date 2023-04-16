import 'package:flutter/material.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_select_multiple.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_select_single.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/form/slist.dart';
import 'package:xml/xml.dart';

enum MgrFormSelectType {
  select,
  multiple,
  radio,
}

MgrFormSelectType _typeFromString(String? type) {
  switch (type) {
    case 'radio':
      return MgrFormSelectType.radio;
    case 'multiple':
      return MgrFormSelectType.multiple;
    default: // TODO
      return MgrFormSelectType.select;
  }
}

class SelectFormFieldControlModel extends FormFieldControlModel {
  final MgrFormSelectType type;
  final String? depend;

  SelectFormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : type = element.convertAttribute('type', converter: _typeFromString),
        depend = element.attribute('depend'),
        super.innerFromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);

  @override
  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    MgrExceptionHolder? exceptionHolder,
  }) =>
      MgrFormSelect(
        controller: controller,
        model: this,
        forceReadOnly: forceReadOnly,
      );
}

class MgrFormSelect extends StatelessWidget {
  final MgrFormController controller;
  final SelectFormFieldControlModel model;
  final bool forceReadOnly;

  const MgrFormSelect({
    Key? key,
    required this.controller,
    required this.model,
    this.forceReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isReadOnly = forceReadOnly || model.isReadonly;
    final param = controller.params[model.name];
    return ValueListenableBuilder<Slist>(
      valueListenable: controller.slists[model.name],
      builder: (context, slist, _) {
        switch (model.type) {
          case MgrFormSelectType.select:
            final controller = param.singleSelectController;
            return MgrFormSelectSingle(
              controller: controller,
              focusNode: controller.focusNode,
              itemHeight: 48.0,
              itemBuilder: (context, entry) => Text(
                entry.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
              onChanged:
                  isReadOnly ? null : (entry) => controller.value = entry.key,
            );
          case MgrFormSelectType.multiple:
            final controller = param.multiSelectController;
            return MgrFormSelectMulti(
              controller: controller,
              itemHeight: 48.0,
              readOnly: isReadOnly,
            );
          case MgrFormSelectType.radio:
            final controller = param.singleSelectController;
            return ValueListenableBuilder<String?>(
              valueListenable: controller,
              builder: (context, value, child) => Column(
                children: [
                  for (final entry in slist)
                    InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      onTap: isReadOnly
                          ? null
                          : () => controller.value = entry.key,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48.0),
                        child: Row(
                          children: [
                            Radio<String?>(
                              value: entry.key,
                              groupValue: value,
                              focusNode: FocusNode(
                                canRequestFocus: false,
                                skipTraversal: true,
                              ),
                              onChanged: isReadOnly
                                  ? null
                                  : (value) => controller.value = value,
                            ),
                            Expanded(
                              child: Text(
                                entry.label,
                                style: TextStyle(
                                  color: isReadOnly
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(.5)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
        }
      },
    );
  }
}
