import 'package:flutter/material.dart';
import 'package:flutter_mgr5/mgr_exception.dart';

const _borderWidth = 2.0;

class MgrFormErrorCard extends StatelessWidget {
  final MgrException exception;

  const MgrFormErrorCard({Key? key, required this.exception}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        border: Border.all(
          color: theme.dividerColor,
          width: _borderWidth,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
      ),
      child: Material(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.error, color: theme.colorScheme.onError),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(exception.toString(),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onError)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
