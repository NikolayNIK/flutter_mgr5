import 'package:flutter/material.dart';
import 'package:flutter_mgr5/mgr5.dart';

class MgrFormTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onRefreshPressed;

  const MgrFormTitle({
    super.key,
    required this.title,
    this.onRefreshPressed,
  });

  MgrFormTitle.fromModel({
    Key? key,
    required MgrFormModel model,
    VoidCallback? onRefreshPressed,
  }) : this(
          key: key,
          title: model.title,
          onRefreshPressed: onRefreshPressed,
        );

  @override
  Widget build(BuildContext context) => Material(
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
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              if (onRefreshPressed != null)
                IconButton(
                  onPressed: onRefreshPressed!,
                  padding: const EdgeInsets.all(16),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
        ),
      );
}
