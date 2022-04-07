import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/mgr5_list.dart';

class StandaloneMgrList extends StatefulWidget {
  final MgrClient mgrClient;
  final String func;
  final Map<String, String>? params;

  const StandaloneMgrList({
    Key? key,
    required this.mgrClient,
    required this.func,
    this.params,
  }) : super(key: key);

  @override
  State<StandaloneMgrList> createState() => _StandaloneMgrListState();
}

class _StandaloneMgrListState extends State<StandaloneMgrList> {
  late Future<void> _loadingFuture;

  MgrListModel? _model;
  MgrListController? _controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StandaloneMgrList oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller?.mgrClient = widget.mgrClient;
  }

  void _load() {
    _model = null;
    _controller?.dispose();
    _controller = null;
    _loadingFuture = () async {
      final doc =
          await widget.mgrClient.requestXmlDocument(widget.func, widget.params);

      setState(() {
        _model = MgrListModel.fromXmlDocument(doc);
        _controller = MgrListController(
            mgrClient: widget.mgrClient,
            func: widget.func,
            params: widget.params)
          ..items.update(_model!);
      });
    }();
  }

  @override
  Widget build(BuildContext context) => _model == null || _controller == null
      ? FutureBuilder(
          builder: (context, snapshot) => snapshot.hasError
              ? Text(snapshot.error?.toString() ?? 'unknown error')
              : const Center(child: CircularProgressIndicator.adaptive()))
      : MgrList(model: _model!, controller: _controller!);
}
