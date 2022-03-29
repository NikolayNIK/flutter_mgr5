import 'package:flutter/widgets.dart';

class ListenableBuilder<T> extends StatefulWidget {
  final Listenable? listenable;
  final WidgetBuilder builder;
  final VoidCallback? callback;

  const ListenableBuilder({
    Key? key,
    required this.listenable,
    required this.builder,
    this.callback,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ListenableBuilderState();
}

class _ListenableBuilderState<T> extends State<ListenableBuilder> {
  @override
  void initState() {
    super.initState();
    widget.listenable?.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ListenableBuilder oldWidget) {
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable?.removeListener(_valueChanged);
      widget.listenable?.addListener(_valueChanged);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.listenable?.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    widget.callback?.call();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
