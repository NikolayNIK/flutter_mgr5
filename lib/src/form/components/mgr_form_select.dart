import 'package:flutter/material.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/form/slist.dart';
import 'package:xml/xml.dart';

enum MgrFormSelectType {
  select,
  radio,
}

MgrFormSelectType _typeFromString(String? type) {
  switch (type) {
    case 'radio':
      return MgrFormSelectType.radio;
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
        depend = element.getAttribute('depend'),
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
    final controller = this.controller.params[model.name].selectController;
    return ValueListenableBuilder<Slist>(
      valueListenable: this.controller.slists[model.name],
      builder: (context, slist, _) {
        switch (model.type) {
          case MgrFormSelectType.select:
            final items = List<DropdownMenuItem<String>>.unmodifiable(
                slist.map((e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(
                      e.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ))));

            return ValueListenableBuilder<String?>(
              valueListenable: controller,
              builder: (context, value, child) => DropdownButton<String>(
                items: items,
                focusNode: controller.focusNode,
                isExpanded: true,
                value: value,
                onChanged:
                    isReadOnly ? null : (value) => controller.value = value,
              ),
            );
          case MgrFormSelectType.radio:
            return ValueListenableBuilder<String?>(
              valueListenable: controller,
              builder: (context, value, child) => Column(
                children: [
                  for (final entry in slist)
                    InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
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
