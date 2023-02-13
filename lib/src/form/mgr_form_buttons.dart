import 'package:flutter/material.dart';
import 'package:flutter_mgr5/mgr5_form.dart';

class MgrFormButtons extends StatelessWidget {
  final MgrFormModel model;
  final MgrFormButtonPressedListener? onPressed;
  final bool forceReadOnly;

  const MgrFormButtons({
    super.key,
    required this.model,
    this.onPressed,
    this.forceReadOnly = false,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                for (final button in model.buttons) _buildButton(button),
              ],
            ),
          ),
        ),
      );

  Widget _buildButton(final MgrFormButtonModel button) {
    final onPressed = this.onPressed == null || forceReadOnly
        ? null
        : () => this.onPressed == null ? null : this.onPressed!(button);

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
}
