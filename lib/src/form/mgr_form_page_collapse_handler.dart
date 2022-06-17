import 'package:flutter/cupertino.dart';
import 'package:flutter_mgr5/src/client/mgr_client.dart';
import 'package:flutter_mgr5/src/client/mgr_request.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';

abstract class MgrFormPageCollapseHandler {
  factory MgrFormPageCollapseHandler({
    required MgrClient mgrClient,
    required MgrFormController formController,
    required MgrFormModel formModel,
  }) =>
      _MgrFormPageCollapseHandler(
          mgrClient: mgrClient,
          formController: formController,
          formModel: formModel);

  set mgrClient(MgrClient mgrClient);

  void dispose();
}

class _MgrFormPageCollapseHandler implements MgrFormPageCollapseHandler {
  final MgrFormController formController;
  final MgrFormModel formModel;
  final _listeners = <MapEntry<MgrFormPageController, VoidCallback>>[];

  @override
  MgrClient mgrClient;

  _MgrFormPageCollapseHandler({
    required this.formController,
    required this.formModel,
    required this.mgrClient,
  }) {
    formController.pages.addCallback(_notify);
  }

  void _notify(String name, MgrFormPageController controller) {
    void listener() => mgrClient.request(MgrRequest.func(
          'collapse',
          {
            'page': name,
            'collapse': controller.value ? 'off' : 'on',
            'action': formModel.func,
          },
        ));

    _listeners.add(MapEntry(controller, listener));
    controller.addListener(listener);
  }

  @override
  void dispose() {
    for (var element in _listeners) {
      element.key.removeListener(element.value);
    }
  }
}
