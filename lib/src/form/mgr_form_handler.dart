import 'package:flutter/cupertino.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';

typedef MgrFormHandlerCallback = void Function(MgrFormControllerParam param);

class MgrFormHandler {
  final MgrFormController formController;
  final List<MapEntry<MgrFormControllerParam, VoidCallback>> _callbacks = [];

  MgrFormHandler(this.formController);

  MgrFormControllerParam addParamCallback(String name, MgrFormHandlerCallback callback) {
    final param = formController.params[name];
    void cb() => callback(param);

    _callbacks.add(MapEntry(param, cb));
    param.addListener(cb);
    return param;
  }

  void dispose() {
    for (final entry in _callbacks) {
      entry.key.removeListener(entry.value);
    }

    _callbacks.clear();
  }
}
