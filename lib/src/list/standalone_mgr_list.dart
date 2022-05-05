import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/iterator_extensions.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/mgr5_list.dart';

class StandaloneMgrList extends StatefulWidget {
  final MgrClient mgrClient;
  final String func;
  final Map<String, String>? params;
  final MgrListToolbtnCallback? onToolbtnPressed;

  const StandaloneMgrList({
    Key? key,
    required this.mgrClient,
    required this.func,
    this.params,
    required this.onToolbtnPressed,
  }) : super(key: key);

  @override
  State<StandaloneMgrList> createState() => _StandaloneMgrListState();
}

class _StandaloneMgrListState extends State<StandaloneMgrList> {
  late Future<void> _loadingFuture;

  Map<String, String>? _filterParams;

  MgrListModel? _model;
  MgrListController? _controller;
  MgrFormModel? _filterModel;
  MgrFormController? _filterController;

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

  String? get _filterFunc => _model?.toolbar
      .expand((element) => element.buttons)
      .where((element) => element.name == 'filter')
      .maybeFirst
      ?.func;

  void _load() {
    final oldFilterFunc = _filterFunc;

    setState(() {
      _model = null;
      _controller?.dispose();
      _controller = null;
      _filterModel = null;
      _filterController?.dispose();
      _filterController = null;
    });

    _loadingFuture = () async {
      if (_filterParams != null && oldFilterFunc != null) {
        await widget.mgrClient.requestXmlDocument(oldFilterFunc, _filterParams);
        _filterParams = null;
      }

      final doc =
          await widget.mgrClient.requestXmlDocument(widget.func, widget.params);

      setState(() {
        _model = MgrListModel.fromXmlDocument(doc);
        _controller = MgrListController(
          mgrClient: widget.mgrClient,
          func: widget.func,
          params: widget.params,
        )..update(_model!);
      });

      final filterFunc = _filterFunc;
      if (filterFunc != null) {
        final filterDoc = await widget.mgrClient
            .requestXmlDocument(filterFunc, widget.params);
        setState(() {
          final model = _filterModel = MgrFormModel.fromXmlDocument(filterDoc);
          _filterController = MgrFormController(model);
        });
      }
    }();
  }

  @override
  Widget build(BuildContext context) => _model == null || _controller == null
      ? FutureBuilder(
          builder: (context, snapshot) => snapshot.hasError
              ? Text(snapshot.error?.toString() ?? 'unknown error')
              : const Center(child: CircularProgressIndicator.adaptive()))
      : MgrList(
          model: _model!,
          controller: _controller!,
          filterModel: _filterModel,
          filterController: _filterController,
          onToolbtnPressed: widget.onToolbtnPressed,
          onFilterSubmitPressed: () {
            _filterParams =
                _filterController?.stringParams.copyWith(map: {'sok': 'ok'});
            _load();
          },
          onFilterDisablePressed: () {
            _filterParams = {
              'drop': 'on',
              'sok': 'ok',
            };
            _load();
          },
        );
}
