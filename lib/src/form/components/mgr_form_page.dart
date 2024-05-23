import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_field.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_field_hint_mode.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';

const _borderWidth = 2.0;

class MgrFormPage extends StatelessWidget {
  final MgrFormController formController;
  final MgrFormModel formModel;
  final MgrFormPageModel page;
  final MgrExceptionHolder exceptionHolder;
  final MgrFormFieldHintMode hintMode;
  final double fieldLabelWidth, fieldControlsWidth;
  final bool forceReadOnly, forceFullWidth;

  const MgrFormPage({
    Key? key,
    required this.formController,
    required this.formModel,
    required this.page,
    required this.exceptionHolder,
    required this.hintMode,
    required this.fieldLabelWidth,
    required this.fieldControlsWidth,
    required this.forceReadOnly,
    required this.forceFullWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MgrFormState state;
    final children = [
      for (final field in page.fields)
        if ((state = formModel.getStateChecker(field.name)(
                    formController.stringParams)) !=
                MgrFormState.gone &&
            !field.isHidden) ...[
          MgrFormField(
            controller: formController,
            model: field,
            exceptionHolder: exceptionHolder.createHolderForField(field.name),
            hintMode: hintMode,
            labelWidth: fieldLabelWidth,
            controlsWidth: fieldControlsWidth,
            forceReadOnly: forceReadOnly || state == MgrFormState.readOnly,
            forceFullWidth: forceFullWidth,
          ),
          SizedBox(
            height: max(.0, 8 + 4 * Theme.of(context).visualDensity.vertical),
          )
        ]
    ];

    if (children.isEmpty) {
      return const SizedBox();
    }

    // remove the last spacer
    children.removeLast();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: page.isDecorated
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: _borderWidth),
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(
                    16.0 - _borderWidth,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: formController.pages[page.name],
                    builder: (context, isExpanded, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (page.title != null)
                          InkWell(
                            onTap: () => formController.pages[page.name].value =
                                !isExpanded,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        page.title!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                  ),
                                  if (page.name != null)
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: ExpandIcon(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        size: 24,
                                        padding: EdgeInsets.zero,
                                        isExpanded: isExpanded,
                                        onPressed: (isExpanded) =>
                                            formController.pages[page.name]
                                                .value = !isExpanded,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (isExpanded)
                          Padding(
                            padding: EdgeInsets.only(
                              left: 16.0,
                              top: page.title == null ? 16.0 : 0.0,
                              right: 16.0,
                              bottom: 16.0,
                            ),
                            child: content,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : content,
    );
  }
}
