import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/form/mgr_form_page_collapse_handler.dart';
import 'package:flutter_mgr5/src/form/mgr_form_setvalues_handler.dart';
import 'package:flutter_mgr5/src/form/mgr_form_validator_handler.dart';
import 'package:flutter_mgr5/src/mgr_client.dart';
import 'package:xml/xml.dart';

class StandaloneMgrFormController extends MgrFormController {
  final MgrFormModel model;
  late final MgrFormSetvaluesHandler setvaluesHandler;
  late final MgrFormValidatorHandler validatorHandler;
  late final MgrFormPageCollapseHandler pageCollapseHandler;

  factory StandaloneMgrFormController.fromXmlDocument(
      MgrClient mgrClient, XmlDocument doc,
      [MgrFormModel? model]) {
    model ??= MgrFormModel.fromXmlDocument(doc);
    final controller = StandaloneMgrFormController(
      mgrClient: mgrClient,
      model: model,
    );
    return controller;
  }

  StandaloneMgrFormController({
    required MgrClient mgrClient,
    required this.model,
    MgrFormSetvaluesHandler? setvaluesHandler,
    MgrFormValidatorHandler? validatorHandler,
    MgrFormPageCollapseHandler? pageCollapseHandler,
  }) : super(model) {
    this.setvaluesHandler = setvaluesHandler ??
        MgrFormSetvaluesHandler(
          mgrClient: mgrClient,
          formController: this,
          formModel: model,
        );

    this.validatorHandler = validatorHandler ??
        MgrFormValidatorHandler(
          mgrClient: mgrClient,
          formController: this,
          formModel: model,
        );

    this.pageCollapseHandler = pageCollapseHandler ??
        MgrFormPageCollapseHandler(
          mgrClient: mgrClient,
          formController: this,
          formModel: model,
        );
  }

  set mgrClient(MgrClient mgrClient) {
    setvaluesHandler.mgrClient = mgrClient;
    validatorHandler.mgrClient = mgrClient;
  }

  bool check() => params.check(model);

  @override
  void dispose() {
    setvaluesHandler.dispose();
    validatorHandler.dispose();
    pageCollapseHandler.dispose();
    super.dispose();
  }
}
