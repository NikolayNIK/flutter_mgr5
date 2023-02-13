import 'package:flutter/material.dart';
import 'package:flutter_mgr5/listenable_builder.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_error_card.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_body.dart';
import 'package:flutter_mgr5/src/form/mgr_form_buttons.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_field_hint_mode.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/form/mgr_form_setvalues_handler.dart';
import 'package:flutter_mgr5/src/form/mgr_form_title.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';

const _defaultFieldLabelWidth = 128.0;
const _defaultFieldControlsWidth = 256.0;
const _defaultFieldMaxWidth = 1024.0;
const _minimumHintTextWidth = 256.0;

const _dividerWidth = 2.0;

const minimumFormWidth = 384.0;

typedef MgrFormButtonPressedListener = void Function(MgrFormButtonModel button);

/// Widget displaying a form built from MgrFormModel.
class MgrForm extends StatefulWidget {
  final MgrFormModel model;
  final MgrFormController controller;
  final MgrFormSetvaluesHandler setvaluesHandler;
  final MgrFormButtonPressedListener? onPressed;
  final MgrFormFieldHintMode? hintMode;
  final double fieldLabelWidth, fieldControlsWidth;
  final double? fieldMaxWidth;
  final bool showTitle, isRefreshing, forceReadOnly;
  final VoidCallback? onRefreshPressed;

  const MgrForm({
    Key? key,
    required this.model,
    required this.controller,
    this.setvaluesHandler = const MgrFormSetvaluesHandler.disabled(),
    this.onPressed,
    this.showTitle = true,
    this.isRefreshing = false,
    this.forceReadOnly = false,
    this.onRefreshPressed,
    this.hintMode,
    this.fieldLabelWidth = _defaultFieldLabelWidth,
    this.fieldControlsWidth = _defaultFieldControlsWidth,
    this.fieldMaxWidth = _defaultFieldMaxWidth,
  }) : super(key: key);

  @override
  State<MgrForm> createState() => _MgrFormState();
}

class _MgrFormState extends State<MgrForm> {
  MgrFormController get controller => widget.controller;

  MgrFormModel get model => widget.model;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => FocusTraversalGroup(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context) => ValueListenableBuilder<MgrException?>(
                  valueListenable: widget.controller.exception,
                  builder: (BuildContext context, exception, Widget? child) =>
                      _build(
                    context,
                    MgrExceptionHolder(exception),
                    widget.hintMode ??
                        (constraints.maxWidth -
                                    widget.fieldLabelWidth -
                                    widget.fieldControlsWidth >
                                _minimumHintTextWidth
                            ? MgrFormFieldHintMode.inline
                            : MgrFormFieldHintMode.floating),
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.setvaluesHandler.formBlocked,
            builder: (context, isBlocked, child) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isBlocked
                  ? GestureDetector(
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(.5),
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      );

  Widget _build(
    BuildContext context,
    MgrExceptionHolder exceptionHolder,
    MgrFormFieldHintMode hintMode,
  ) =>
      Column(
        children: [
          if (widget.showTitle) ...[
            MgrFormTitle.fromModel(
              model: model,
              onRefreshPressed: widget.onRefreshPressed,
            ),
            const Divider(
              height: _dividerWidth,
              thickness: _dividerWidth,
              indent: 16.0,
            ),
          ],
          Flexible(
            child: FocusTraversalGroup(
              child: CustomScrollView(
                controller: controller.scrollController,
                shrinkWrap: true,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    sliver: SliverMgrFormBody(
                      model: model,
                      controller: controller,
                      fieldMaxWidth: widget.fieldMaxWidth,
                      hintMode: hintMode,
                      fieldLabelWidth: _defaultFieldLabelWidth,
                      fieldControlsWidth: _defaultFieldControlsWidth,
                      forceReadOnly: widget.forceReadOnly,
                      exceptionHolder: exceptionHolder,
                    ),
                  )
                ],
              ),
            ),
          ),
          if (widget.onPressed != null) ...[
            const Divider(
              height: _dividerWidth,
              thickness: _dividerWidth,
              indent: 16.0,
            ),
            MgrFormButtons(
              model: model,
              onPressed: widget.onPressed,
              forceReadOnly: widget.forceReadOnly,
            ),
            Builder(
              builder: (context) {
                final exception = exceptionHolder.consume();
                return exception == null
                    ? const SizedBox(height: 16.0)
                    : _buildError(exception);
              },
            ),
          ],
        ],
      );

  Widget _buildError(final MgrException exception) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: MgrFormErrorCard(exception: exception));
}
