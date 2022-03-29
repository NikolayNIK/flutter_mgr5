import 'package:flutter/material.dart';
import 'package:flutter_mgr5/listenable_builder.dart';
import 'package:flutter_mgr5/form/components/mgr_form_error_card.dart';
import 'package:flutter_mgr5/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/form/mgr_form_field_hint_mode.dart';
import 'package:flutter_mgr5/form/mgr_form_model.dart';

class MgrFormField extends StatelessWidget {
  final MgrFormController controller;
  final MgrFormFieldModel model;
  final MgrExceptionHolder? exceptionHolder;
  final MgrFormFieldHintMode hintMode;
  final double labelWidth, controlsWidth;
  final bool forceReadOnly;

  const MgrFormField({
    Key? key,
    required this.controller,
    required this.model,
    required this.exceptionHolder,
    required this.hintMode,
    required this.labelWidth,
    required this.controlsWidth,
    this.forceReadOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      _wrapException(_wrapHints(_build(context)));

  Widget _wrapException(Widget widget) {
    final exception = exceptionHolder?.consume();
    if (exception != null) {
      widget = Column(
        children: [
          widget,
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IntrinsicWidth(
                child: MgrFormErrorCard(exception: exception),
              ),
            ),
          ),
        ],
      );
    }

    return widget;
  }

  Widget _wrap(Widget widget) =>
      model.isFullWidth ? Expanded(child: widget) : Flexible(child: widget);

  Widget _wrapHints(Widget widget) {
    final hintMode =
        model.isFullWidth && this.hintMode == MgrFormFieldHintMode.inline
            ? MgrFormFieldHintMode.floating
            : this.hintMode;

    if (hintMode != MgrFormFieldHintMode.disabled && model.hint == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 24.0 + 8.0),
        child: widget,
      );
    }

    switch (hintMode) {
      case MgrFormFieldHintMode.inline:
        // ignore: unnecessary_cast
        var builder = (bool isActive) => Row(
              children: [
                widget,
                const SizedBox(width: 8.0),
                Builder(
                  builder: (context) => Icon(
                    Icons.help_outline,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    child: isActive
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(model.hint ?? ''),
                            ),
                          )
                        : const SizedBox(
                            width: double.infinity,
                          ),
                  ),
                ),
              ],
            ) as Widget;

        for (final control in model.controls) {
          final b = builder;
          final focusNode = controller.params[control.name].focusNode;
          builder = (isActive) => ListenableBuilder(
                listenable: focusNode,
                builder: (context) => b(isActive || focusNode.hasFocus),
              );
        }

        return _HoverDetector(
          builder: (context, value, child) => builder(value),
        );
      case MgrFormFieldHintMode.floating:
        return Row(
          children: [
            _wrap(widget),
            const SizedBox(width: 8.0),
            SizedBox(
              width: 24,
              height: 24,
              child: model.hint == null
                  ? Container()
                  : Tooltip(
                      message: model.hint,
                      triggerMode: TooltipTriggerMode.tap,
                      child: Builder(
                        builder: (context) => Icon(
                          Icons.help_outline,
                          size: 24,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
            ),
          ],
        );
      default:
        return widget;
    }
  }

  Widget _build(BuildContext context) {
    final exceptionHolder =
        model.controls.length == 1 ? this.exceptionHolder : null;
    Widget controls = Row(
      children: [
        for (final control in model.controls)
          if (!control.isHidden)
            Expanded(
              child: control.build(
                controller: controller,
                forceReadOnly: forceReadOnly,
                exceptionHolder: exceptionHolder,
              ),
            ),
      ],
    );

    if (!model.isFullWidth) {
      controls = SizedBox(
        width: controlsWidth,
        child: controls,
      );
    }

    if (model.isNameLabelDisabled) {
      return controls;
    }

    final label = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (model.title != null)
          Expanded(
            child: Text(
              model.title!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (model.controls.any((control) => control.isRequired))
          Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
            ),
            child: SizedBox(
              height: 18,
              child: Text(
                '*',
                style: TextStyle(
                  color: !forceReadOnly &&
                          model.controls.any((control) =>
                              !control.isReadonly && !control.isHidden)
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(.5),
                  fontSize: 24,
                ),
              ),
            ),
          )
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56.0),
      child: model.isFullWidth
          ? Column(children: [
              const SizedBox(
                height: 16.0,
              ),
              Align(
                  alignment: Alignment.centerLeft,
                  child: IntrinsicWidth(child: label)),
              controls,
            ])
          : IntrinsicWidth(
              child: Row(
                children: [
                  SizedBox(width: labelWidth, child: label),
                  Flexible(child: controls),
                ],
              ),
            ),
    );
  }
}

class _HoverDetector extends StatefulWidget {
  final ValueWidgetBuilder<bool> builder;
  final Widget? child;

  const _HoverDetector({Key? key, required this.builder, this.child})
      : super(key: key);

  @override
  State<_HoverDetector> createState() => _HoverDetectorState();
}

class _HoverDetectorState extends State<_HoverDetector> {
  bool isInside = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (event) => setState(() => isInside = true),
        onExit: (event) => Future.delayed(const Duration(milliseconds: 100))
            .then((value) => setState(() => isInside = false)),
        child: widget.builder(context, isInside, widget.child),
      );
}
