import 'package:flutter/material.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/form/mgr_form.dart';
import 'package:flutter_mgr5/form/mgr_form_model.dart';
import 'package:flutter_mgr5/form/standalone_mgr_form_controller.dart';
import 'package:flutter_mgr5/mgr_client.dart';
import 'package:flutter_mgr5/mgr_exception.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';

typedef StandaloneMgrFormButtonPressedListener = bool? Function(
    MgrFormButtonModel button, String func, Map<String, String> params);

typedef StandaloneMgrFormSubmitCallback = Future<bool?>? Function(
    Map<String, String> params, XmlDocument response);

typedef StandaloneMgrFormModelAdjuster = MgrFormModel Function(
    MgrFormModel model);

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

  bool isRefreshing = false, isSubmitting = false;

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
      _controller?.dispose();
      _controller = null;

      _initialLoadFuture = () async {
        final doc = await widget.mgrClient.request(widget.name, widget.params);
        setState(() {
          _controller = StandaloneMgrFormController.fromXmlDocument(
              widget.mgrClient,
              doc,
              widget.modelAdjuster == null
                  ? null
                  : widget.modelAdjuster!(MgrFormModel.fromXmlDocument(doc)));

          isRefreshing = false;
        });
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
        response =
            await widget.mgrClient.request(controller.model.func, params);
      } on MgrException catch (e) {
        controller.exception.value = e;
        setState(() => _controller = controller);
        return;
      }

      if (additionalParams != null) {
        if (additionalParams['sok'] == 'ok') {
          if (additionalParams['snext'] == 'ok' ||
              additionalParams['sback'] == 'ok') {
            setState(() {
              _controller = StandaloneMgrFormController.fromXmlDocument(
                context.read<MgrClient>(),
                response,
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

    _controller?.dispose();
  }
}
