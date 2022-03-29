import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_handler.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/mgr_client.dart';

abstract class MgrFormSetvaluesHandler {
  factory MgrFormSetvaluesHandler({
    required MgrClient mgrClient,
    required MgrFormController formController,
    required MgrFormModel formModel,
  }) =>
      MgrFormSetValuesHandlerImpl(
          mgrClient: mgrClient,
          formController: formController,
          formModel: formModel);

  const factory MgrFormSetvaluesHandler.disabled() =
      _DisabledMgrFormSetvaluesHandler;

  ValueListenable<bool> get formBlocked;

  set mgrClient(MgrClient mgrClient);

  void dispose();
}

class _ConstFalseValueListenable implements ValueListenable<bool> {
  const _ConstFalseValueListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get value => false;
}

class _DisabledMgrFormSetvaluesHandler implements MgrFormSetvaluesHandler {
  const _DisabledMgrFormSetvaluesHandler();

  @override
  final ValueListenable<bool> formBlocked = const _ConstFalseValueListenable();

  @override
  void dispose() {}

  @override
  set mgrClient(MgrClient mgrClient) {}
}

class MgrFormSetValuesHandlerImpl extends MgrFormHandler
    implements MgrFormSetvaluesHandler {
  MgrClient _mgrClient;

  final MgrFormModel formModel;
  final Set<String> _finalSvFields = {};
  final Set<String> _blockingSvFields = {};
  final List<Timer> _periodicalTasks = [];
  final ValueNotifier<bool> _formBlocked = ValueNotifier(false);

  MgrFormSetValuesHandlerImpl({
    required MgrFormController formController,
    required MgrClient mgrClient,
    required this.formModel,
  })  : _mgrClient = mgrClient,
        super(formController) {
    formModel.pages
        .expand((page) => page.fields)
        .expand((field) => field.controls)
        .where((control) => control.setValuesOptions != null)
        .forEach(handleControl);
  }

  @override
  ValueListenable<bool> get formBlocked => _formBlocked;

  @override
  set mgrClient(MgrClient mgrClient) => _mgrClient = mgrClient;

  void handleControl(FormFieldControlModel control) {
    final setvaluesOptions = control.setValuesOptions!;
    final name = control.name;
    final callback = createCallback(name, setvaluesOptions);
    if (callback == null) {
      return;
    }

    final param = setvaluesOptions.isTriggeredOnChange
        ? addParamCallback(name, callback)
        : formController.params[name];

    if (setvaluesOptions.isPeriodic) {
      _periodicalTasks.add(Timer.periodic(
        setvaluesOptions.period!,
        (timer) => callback(param),
      ));
    }
  }

  MgrFormHandlerCallback? createCallback(
    String name,
    MgrFormSetValuesOptions setvaluesOptions,
  ) {
    final isFinal = setvaluesOptions.isFinal;
    final isBlocking = setvaluesOptions.isBlocking;
    return (final MgrFormControllerParam param) async {
      if (_finalSvFields.isNotEmpty) {
        return;
      }

      if (isBlocking) {
        _blockingSvFields.add(name);
        _formBlocked.value = true;
      }

      try {
        final doc = await _mgrClient.request(
          formModel.func,
          formController.stringParams.copyWith(map: {'sv_field': name}),
        );

        if (_finalSvFields.isNotEmpty) {
          return;
        }

        if (isFinal) {
          _finalSvFields.add(name);
        }

        formController.params.set(MgrFormModel.fromXmlDocument(doc));
        formController.update(doc: doc);

        if (isFinal) {
          _finalSvFields.remove(name);
        }
      } finally {
        if (isBlocking) {
          _blockingSvFields.remove(name);
          _formBlocked.value = _blockingSvFields.isNotEmpty;
        }
      }
    };
  }

  @override
  void dispose() {
    super.dispose();

    for (var element in _periodicalTasks) {
      element.cancel();
    }

    _periodicalTasks.clear();
  }
}
