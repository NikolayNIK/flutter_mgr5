import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mgr5/listenable_builder.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_error_card.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_page.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_field_hint_mode.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/form/mgr_form_setvalues_handler.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';

const _defaultFieldLabelWidth = 128.0;
const _defaultFieldControlsWidth = 256.0;
const _defaultFieldMaxWidth = 1024.0;
const _minimumHintTextWidth = 256.0;

const _dividerWidth = 2.0;

const minimumFormWidth = 384.0;

typedef MgrFormButtonPressedListener = void Function(MgrFormButtonModel button);

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
            _buildTitle(context),
            const Divider(
              height: _dividerWidth,
              thickness: _dividerWidth,
              indent: 16.0,
            ),
          ],
          Flexible(
            child: FocusTraversalGroup(
              child: ListView(
                controller: controller.scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: [
                  for (final page in widget.model.pages)
                    if (page.name == null ||
                        widget.model.getStateChecker(page.name!)(
                                    widget.controller.stringParams) !=
                                MgrFormState.gone &&
                            !page.isHidden)
                      widget.fieldMaxWidth == null
                          ? _buildPage(page, exceptionHolder, hintMode)
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: widget.fieldMaxWidth!),
                                child:
                                    _buildPage(page, exceptionHolder, hintMode),
                              ),
                            ),
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
            Material(
              color: Colors.transparent,
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing: 16.0,
                    runSpacing: 8.0,
                    children: [
                      for (final button in widget.model.buttons)
                        _buildButton(button),
                    ],
                  ),
                ),
              ),
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

  Widget _buildTitle(BuildContext context) => Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.model.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              if (widget.onRefreshPressed != null)
                IconButton(
                  onPressed: widget.onRefreshPressed!,
                  padding: const EdgeInsets.all(16),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
        ),
      );

  Widget _buildError(final MgrException exception) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: MgrFormErrorCard(exception: exception));

  Widget _buildButton(final MgrFormButtonModel button) {
    final onPressed = widget.onPressed == null || widget.forceReadOnly
        ? null
        : () => widget.onPressed == null ? null : widget.onPressed!(button);

    return button.color == null
        ? OutlinedButton(
            onPressed: onPressed,
            child: Text(button.label),
          )
        : Theme(
            data: ThemeData.from(
                colorScheme: button.color!.computeLuminance() > .5
                    ? ColorScheme.dark(primary: button.color!)
                    : ColorScheme.light(primary: button.color!)),
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(button.label),
            ),
          );
  }

  Widget _buildPage(
    final MgrFormPageModel page,
    final MgrExceptionHolder exceptionHolder,
    final MgrFormFieldHintMode hintMode,
  ) =>
      MgrFormPage(
        formController: widget.controller,
        formModel: widget.model,
        page: page,
        exceptionHolder: exceptionHolder,
        hintMode: hintMode,
        fieldLabelWidth: widget.fieldLabelWidth,
        fieldControlsWidth: widget.fieldControlsWidth,
        forceReadOnly: widget.forceReadOnly,
      );
}
