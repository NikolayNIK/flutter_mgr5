import 'package:flutter/material.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/src/client/mgr_client.dart';
import 'package:flutter_mgr5/src/client/mgr_request.dart';
import 'package:flutter_mgr5/src/client/xml_mgr_client.dart';
import 'package:flutter_mgr5/src/form/mgr_form.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/form/standalone_mgr_form_controller.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';
import 'package:xml/xml.dart';

typedef StandaloneMgrFormButtonPressedListener = bool? Function(
    MgrFormButtonModel button, String func, Map<String, String> params);

typedef StandaloneMgrFormSubmitCallback = Future<bool?>? Function(
    Map<String, String> params, XmlDocument response);

typedef StandaloneMgrFormModelAdjuster = MgrFormModel Function(
    MgrFormModel model);

/// Widget that handles downloading and building MgrForm used primarily for
/// embedding purposes. APIs are subject to change.
class StandaloneMgrForm extends StatelessWidget {
  final MgrClient mgrClient;
  final String func;
  final Map<String, String>? params;
  final StandaloneMgrFormButtonPressedListener? onPressed;
  final StandaloneMgrFormSubmitCallback? onSubmitted;
  final StandaloneMgrFormModelAdjuster? modelAdjuster;
  final bool showTitle, showRefresh;

  const StandaloneMgrForm({
    Key? key,
    required this.mgrClient,
    required this.func,
    this.params,
    this.onPressed,
    this.onSubmitted,
    this.showTitle = true,
    this.showRefresh = true,
    this.modelAdjuster,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => _StandaloneMgrFormImpl(
        key: key,
        mgrClient: mgrClient,
        name: func,
        params: params,
        onPressed: onPressed,
        onSubmitted: onSubmitted,
        showTitle: showTitle,
        showRefresh: showRefresh,
        modelAdjuster: modelAdjuster,
      );
}

class _StandaloneMgrFormImpl extends StatefulWidget {
  final MgrClient mgrClient;
  final String name;
  final Map<String, String>? params;
  final StandaloneMgrFormButtonPressedListener? onPressed;
  final StandaloneMgrFormSubmitCallback? onSubmitted;
  final StandaloneMgrFormModelAdjuster? modelAdjuster;
  final bool showTitle, showRefresh;

  const _StandaloneMgrFormImpl({
    Key? key,
    required this.mgrClient,
    required this.name,
    this.params,
    this.onPressed,
    this.onSubmitted,
    this.showTitle = true,
    this.showRefresh = true,
    this.modelAdjuster,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StandaloneMgrFormState();
}

class _StandaloneMgrFormState extends State<_StandaloneMgrFormImpl> {
  StandaloneMgrFormController? _controller;

  late Future<void> _initialLoadFuture;

  bool isRefreshing = false, isSubmitting = false, isDisposed = false;

  @override
  void initState() {
    super.initState();

    _refresh();
  }

  @override
  void didUpdateWidget(covariant _StandaloneMgrFormImpl oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller?.mgrClient = widget.mgrClient;
  }

  void _refresh() {
    setState(() {
      // вызывает проблемы, т.к. виджеты вызывают removeListener у содержащихся
      // в контроллере [Listenable] после смены контроллера
      // _controller?.dispose(); // что может пойти не так?
      _controller = null;

      _initialLoadFuture = () async {
        final model = await widget.mgrClient
                .requestModel(MgrRequest.func(widget.name, widget.params))
            as MgrFormModel;
        if (!isDisposed) {
          setState(() {
            _controller = StandaloneMgrFormController(
              mgrClient: widget.mgrClient,
              model: widget.modelAdjuster == null
                  ? model
                  : widget.modelAdjuster!(model),
            );

            isRefreshing = false;
          });
        }
      }();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _initialLoadFuture,
        builder: (context, snapshot) => Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: snapshot.hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          snapshot.error?.toString() ?? 'null',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _controller != null
                      ? KeyedSubtree(
                          key: ValueKey(_controller),
                          child: MgrForm(
                            model: _controller!.model,
                            controller: _controller!,
                            setvaluesHandler: _controller!.setvaluesHandler,
                            forceReadOnly: isSubmitting,
                            onPressed: (button) {
                              // ignore: missing_enum_constant_in_switch
                              switch (button.type) {
                                case MgrFormButtonType.ok:
                                case MgrFormButtonType.next:
                                  if (!check()) return;
                              }

                              try {
                                if (widget.onPressed == null ||
                                    !(widget.onPressed!(
                                            button,
                                            _controller!.model.func,
                                            _controller!.stringParams) ??
                                        false)) {
                                  switch (button.type) {
                                    case MgrFormButtonType.ok:
                                      submit({
                                        'sok': 'ok',
                                        'clicked_button': button.name,
                                      });
                                      break;
                                    case MgrFormButtonType.cancel:
                                      break;
                                    case MgrFormButtonType.back:
                                      submit({
                                        'sok': 'ok',
                                        'sback': 'ok',
                                        'clicked_button': button.name,
                                      });
                                      break;
                                    case MgrFormButtonType.next:
                                      submit({
                                        'sok': 'ok',
                                        'snext': 'ok',
                                        'clicked_button': button.name,
                                      });
                                      break;
                                    case MgrFormButtonType.blank:
                                      submit({
                                        'sok': 'ok',
                                        'clicked_button': button.name,
                                      });
                                      break;
                                    case MgrFormButtonType.setvalues:
                                      // TODO: Handle this case.
                                      break;
                                    case MgrFormButtonType.func:
                                      // TODO: Handle this case.
                                      break;
                                    case MgrFormButtonType.reset:
                                      _refresh();
                                      break;
                                  }
                                }
                              } on MgrException catch (e) {
                                _controller?.exception.value = e;
                              }
                            },
                            showTitle: widget.showTitle,
                            isRefreshing: isRefreshing,
                            onRefreshPressed:
                                widget.showRefresh ? _refresh : null,
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator.adaptive()),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSubmitting
                  ? Container(
                      color:
                          Theme.of(context).colorScheme.surface.withOpacity(.5),
                      child: const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      );

  bool check() => _controller?.check() ?? false;

  void submit([Map<String, String>? additionalParams]) async {
    if ((additionalParams == null || additionalParams['sback'] != 'ok') &&
        !check()) {
      return;
    }

    final controller = _controller!;
    final params = controller.stringParams.copyWith(map: additionalParams);

    setState(() => isSubmitting = true);

    try {
      final XmlDocument response;
      try {
        final mgrClient = widget.mgrClient;
        if (mgrClient is XmlMgrClient) {
          response = await mgrClient.requestXmlDocument(
              MgrRequest.func(controller.model.func, params));
        } else {
          throw MgrException('unsupported', 'MgrClient', null, null); // TODO
        }
      } on MgrException catch (e) {
        controller.exception.value = e;
        return;
      }

      if (additionalParams != null) {
        if (additionalParams['sok'] == 'ok') {
          if (additionalParams['snext'] == 'ok' ||
              additionalParams['sback'] == 'ok') {
            setState(() {
              // вызывает проблемы, т.к. виджеты вызывают removeListener у содержащихся
              // в контроллере [Listenable] после смены контроллера
              // _controller?.dispose(); // что может пойти не так?
              _controller = StandaloneMgrFormController(
                mgrClient: widget.mgrClient,
                model: MgrFormModel.fromXmlDocument(response),
              );
            });

            return;
          }
        }
      }

      if (widget.onSubmitted != null) {
        final future = widget.onSubmitted!(params, response);
        if (future != null && (await future ?? false)) {
          return;
        }
      }

      _refresh();
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    super.dispose();

    isDisposed = true;
    _controller?.dispose();
  }
}
