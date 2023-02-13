import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_page.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_field_hint_mode.dart';

import '../../mgr5_form.dart';

class SliverMgrFormBody extends StatelessWidget {
  final MgrFormController controller;
  final MgrFormModel model;
  final MgrFormFieldHintMode hintMode;
  final double? fieldMaxWidth;
  final double fieldLabelWidth;
  final double fieldControlsWidth;
  final bool forceReadOnly;
  final MgrExceptionHolder exceptionHolder;

  const SliverMgrFormBody({
    super.key,
    required this.model,
    required this.controller,
    required this.hintMode,
    required this.fieldMaxWidth,
    required this.fieldLabelWidth,
    required this.fieldControlsWidth,
    required this.forceReadOnly,
    required this.exceptionHolder,
  });

  @override
  Widget build(BuildContext context) => SliverList(
          delegate: SliverChildListDelegate([
        for (final page in model.pages)
          if (page.name == null ||
              model.getStateChecker(page.name!)(controller.stringParams) !=
                      MgrFormState.gone &&
                  !page.isHidden)
            fieldMaxWidth == null
                ? _buildPage(page, exceptionHolder, hintMode)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: fieldMaxWidth!),
                      child: _buildPage(page, exceptionHolder, hintMode),
                    ),
                  ),
      ]));

  Widget _buildPage(
      final MgrFormPageModel page,
      final MgrExceptionHolder exceptionHolder,
      final MgrFormFieldHintMode hintMode,
      ) =>
      MgrFormPage(
        formController: controller,
        formModel: model,
        page: page,
        exceptionHolder: exceptionHolder,
        hintMode: hintMode,
        fieldLabelWidth: fieldLabelWidth,
        fieldControlsWidth: fieldControlsWidth,
        forceReadOnly: forceReadOnly,
      );
}
