import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_handler.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/mgr_client.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';

abstract class MgrFormValidatorHandler {
  factory MgrFormValidatorHandler({
    required MgrClient mgrClient,
    required MgrFormController formController,
    required MgrFormModel formModel,
  }) =>
      _MgrFormValidatorHandler(
          mgrClient: mgrClient,
          formController: formController,
          formModel: formModel);

  set mgrClient(MgrClient mgrClient);

  void dispose();
}

class _MgrFormValidatorHandler extends MgrFormHandler
    implements MgrFormValidatorHandler {
  MgrClient _mgrClient;

  final MgrFormModel formModel;
  final Set<String> _blockedValidators = {};

  _MgrFormValidatorHandler({
    required MgrFormController formController,
    required MgrClient mgrClient,
    required this.formModel,
  })  : _mgrClient = mgrClient,
        super(formController) {
    for (final control in formModel.pages
        .expand((page) => page.fields)
        .expand((field) => field.controls)
        .where((control) => control.validatorOptions != null)) {
      final validatorOptions = control.validatorOptions!;
      final name = control.name;
      final convert = control.convert;

      addParamCallback(name, (param) {
        if (_blockedValidators.contains(name)) {
          return;
        }

        final value = param.value;
        _mgrClient.request('check.${validatorOptions.func}', {
          'name': name,
          'funcname': formModel.func,
          if (value != null) 'value': value,
          if (convert != null) 'tconvert': convert,
          if (validatorOptions.args != null) 'args': validatorOptions.args!,
        }).then((doc) {
          if (_blockedValidators.contains(name)) {
            return;
          }

          // если значение изменилось с момента вызова валидатора, его результат игнорируется
          if (param.value == value) {
            final element = doc.rootElement.child('value');
            if (element != null) {
              _blockedValidators.add(name);
              param.value = element.innerText;
              _blockedValidators.remove(name);
            }
          }
        }).catchError((error) => formController.exception.value = error,
            test: (error) => error is MgrException);
      });
    }
  }

  @override
  set mgrClient(MgrClient mgrClient) => _mgrClient = mgrClient;
}
