import 'package:flutter/material.dart';
import 'package:flutter_mgr5/extensions/iterator_extensions.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_captcha.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_check.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_datetime.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_desc.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_frame.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_html_data.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_img.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_link.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_list.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_select.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_slider.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_text_area.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_text_data.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_text_input.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_ticket.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_tree.dart';
import 'package:flutter_mgr5/src/form/mgr_exception_holder.dart';
import 'package:flutter_mgr5/src/form/mgr_form_controller.dart';
import 'package:flutter_mgr5/src/form/slist.dart';
import 'package:flutter_mgr5/src/mgr_format.dart';
import 'package:flutter_mgr5/src/mgr_messages.dart';
import 'package:flutter_mgr5/src/mgr_model.dart';
import 'package:xml/xml.dart';

typedef MgrConditionalStateChecker = MgrFormState Function(
    Map<String, String?> controller);

typedef ConditionalStateCheckerConsumer = void Function(
    String name, MgrConditionalStateChecker checker);

@immutable
class MgrFormModel extends MgrModel {
  @override
  final String title;
  final String? elid, plid;
  final List<MgrFormPageModel> pages;
  final List<MgrFormButtonModel> buttons;
  final Map<String, MgrConditionalStateChecker> conditionalStateChecks;
  final Map<String, Slist> slists;

  const MgrFormModel({
    required String func,
    required this.title,
    required this.elid,
    required this.plid,
    required this.pages,
    required this.buttons,
    required this.conditionalStateChecks,
    required this.slists,
  }) : super(func);

  factory MgrFormModel.fromXmlDocument(XmlDocument doc,
          {MgrFormatExceptionReporter? reporter}) =>
      MgrFormModel.fromXmlElement(doc.rootElement, reporter: reporter);

  factory MgrFormModel.fromXmlElement(XmlElement rootElement,
      {MgrFormatExceptionReporter? reporter}) {
    final messages = parseMessages(rootElement);
    final title = messages['title'] ?? '';
    final conditionalStateChecks = <String, MgrConditionalStateChecker>{};

    void conditionalHideConsumer(name, checker) {
      if (conditionalStateChecks.containsKey(name)) {
        final previous = conditionalStateChecks[name];
        if (previous != null) {
          conditionalStateChecks[name] =
              (controller) => previous(controller) | checker(controller);
          return;
        }
      }

      conditionalStateChecks[name] = checker;
    }

    final metadata = rootElement.findElements('metadata');
    final form = metadata.expand((element) => element.findElements('form'));

    return MgrFormModel(
      func: rootElement.requireAttribute('func'),
      title: title,
      elid: rootElement
          .findElements('elid')
          .map((e) => e.innerText)
          .joinOrNull(', '),
      plid: rootElement
          .findElements('plid')
          .map((e) => e.innerText)
          .joinOrNull(', '),
      pages: _parsePages(messages, conditionalHideConsumer, form),
      buttons: _parseButtons(messages, form),
      conditionalStateChecks: Map.unmodifiable(conditionalStateChecks),
      slists: {
        for (final slist in rootElement.findElements('slist'))
          slist.requireAttribute('name'): List.unmodifiable(
            slist.childElements.map(
              (item) => SlistEntry(
                item.attribute('key'),
                item.innerText,
                item.attribute('depend'),
              ),
            ),
          ),
      },
    );
  }

  MgrConditionalStateChecker getStateChecker(final String name) =>
      conditionalStateChecks[name] ?? (_) => MgrFormState.visible;

  FormFieldControlModel? findControlByName(String name) {
    for (final control in pages
        .expand((element) => element.fields)
        .expand((element) => element.controls)
        .where((element) => element.name == name)) {
      return control;
    }

    return null;
  }

  MgrFormModel copyWith({
    String? func,
    String? title,
    String? elid,
    String? plid,
    List<MgrFormPageModel>? pages,
    List<MgrFormButtonModel>? buttons,
    Map<String, MgrConditionalStateChecker>? conditionalStateChecks,
    Map<String, Slist>? slists,
  }) =>
      MgrFormModel(
        func: func ?? this.func,
        title: title ?? this.title,
        elid: elid ?? this.elid,
        plid: plid ?? this.plid,
        pages: pages ?? this.pages,
        buttons: buttons ?? this.buttons,
        conditionalStateChecks:
            conditionalStateChecks ?? this.conditionalStateChecks,
        slists: slists ?? this.slists,
      );

  static List<MgrFormPageModel> _parsePages(
      MgrMessages messages,
      ConditionalStateCheckerConsumer conditionalStateCheckerConsumer,
      Iterable<XmlElement> form) {
    final pages = <MgrFormPageModel>[];

    MgrFormPageModel? page;
    void flushPage() {
      if (page != null) {
        pages.add(MgrFormPageModel(
          page.name,
          isDecorated: page.isDecorated,
          messages: messages,
          fields: List.unmodifiable(page.fields),
          isCollapsed: page.isCollapsed,
        ));
      }
    }

    for (final child in form
        .expand<XmlElement>((element) => element.childElements)
        .expand<XmlElement>((element) => element.name.local == 'page'
            ? element.childElements
            : element.name.local == 'buttons'
                ? const Iterable.empty()
                : [element])) {
      final parentElement = child.parentElement;
      if (page == null ||
          page.name !=
              (parentElement?.name.local == 'page'
                  ? parentElement?.attribute('name')
                  : null)) {
        flushPage();
        page = MgrFormPageModel(
          parentElement?.attribute('name'),
          isDecorated: parentElement?.name.local == 'page',
          messages: messages,
          // ignore: prefer_const_literals_to_create_immutables
          fields: [],
          isCollapsed: parentElement?.boolAttribute('collapsed') ?? false,
        );
      }

      page.fields.add(MgrFormFieldModel.fromXmlElement(child,
          messages: messages,
          conditionalStateCheckerConsumer: conditionalStateCheckerConsumer));
    }

    flushPage();

    return List.unmodifiable(pages);
  }

  static List<MgrFormButtonModel> _parseButtons(
          MgrMessages messages, Iterable<XmlElement> form) =>
      List.unmodifiable(form
          .expand((element) => element.findElements('buttons'))
          .expand((element) => element.childElements)
          .map((e) {
        if (e.name.local != 'button') {
          throw MgrUnexpectedTagException(e);
        }

        return MgrFormButtonModel.fromXmlElement(e, messages: messages);
      }));
}

enum MgrFormButtonType { ok, cancel, back, next, blank, setvalues, func, reset }

MgrFormButtonType _mgrFormButtonTypeFromString(String type) {
  const _map = <String, MgrFormButtonType>{
    'ok': MgrFormButtonType.ok,
    'cancel': MgrFormButtonType.cancel,
    'back': MgrFormButtonType.back,
    'next': MgrFormButtonType.next,
    'blank': MgrFormButtonType.blank,
    'setvalues': MgrFormButtonType.setvalues,
    'func': MgrFormButtonType.func,
    'reset': MgrFormButtonType.reset,
  };

  final result = _map[type];
  if (result == null) {
    throw MgrFormatException('Invalid button type: "$type"'); // TODO
  }
  return result;
}

@immutable
class MgrFormButtonModel {
  final String name;
  final MgrFormButtonType type;
  final String label;
  final String? func;
  final Color? color;
  final bool keepform, blocking, disabled;

  const MgrFormButtonModel({
    required this.name,
    required this.type,
    required this.label,
    required this.func,
    required this.color,
    required this.keepform,
    required this.blocking,
    required this.disabled,
  });

  factory MgrFormButtonModel.fromXmlElement(XmlElement element,
      {required MgrMessages messages}) {
    final Color? color;
    switch (element.attribute('color')) {
      case 'blue':
        color = Colors.blueAccent.shade400;
        break;
      case 'cyan':
        color = Colors.cyanAccent.shade400;
        break;
      case 'green':
        color = Colors.greenAccent.shade400;
        break;
      case 'red':
        color = Colors.redAccent.shade400;
        break;
      case 'yellow':
        color = Colors.yellowAccent.shade400;
        break;
      default:
        color = null;
        break;
    }

    final name = element.requireAttribute('name');
    return MgrFormButtonModel(
      name: name,
      type: element.requireConvertAttribute('type',
          converter: _mgrFormButtonTypeFromString),
      label: messages['msg_$name'] ?? '',
      func: element.attribute('func'),
      color: color,
      keepform: element.boolAttribute('keepform'),
      blocking: element.boolAttribute('blocking'),
      disabled: element.boolAttribute('disabled'),
    );
  }
}

enum MgrFormState { visible, readOnly, gone }

extension MgrFormFieldStatusOperator on MgrFormState {
  operator |(MgrFormState other) {
    switch (this) {
      case MgrFormState.visible:
        return other;
      case MgrFormState.readOnly:
        return other == MgrFormState.gone
            ? MgrFormState.gone
            : MgrFormState.readOnly;
      case MgrFormState.gone:
        return MgrFormState.gone;
    }
  }
}

@immutable
class MgrFormPageModel {
  final String? name, title;
  final List<MgrFormFieldModel> fields;
  final bool isDecorated, isCollapsed;

  MgrFormPageModel(
    this.name, {
    required this.isDecorated,
    required MgrMessages messages,
    required this.fields,
    required this.isCollapsed,
  }) : title = messages[name];

  bool get isHidden => !fields.any((element) => !element.isHidden);
}

@immutable
class MgrFormFieldModel {
  final String name;
  final bool isFullWidth, isNameLabelDisabled;
  final List<FormFieldControlModel> controls;
  final String? title, hint, shadowHint;

  const MgrFormFieldModel({
    required this.name,
    required this.title,
    required this.hint,
    required this.shadowHint,
    required this.isFullWidth,
    required this.isNameLabelDisabled,
    required this.controls,
  });

  factory MgrFormFieldModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalStateCheckerConsumer}) {
    final name = element.requireAttribute('name');
    return MgrFormFieldModel(
      name: name,
      title: messages[name],
      hint: messages['hint_$name'],
      shadowHint: messages['shadow_hint_$name'],
      isFullWidth: element.boolAttribute('fullwidth') ||
          element.boolAttribute('formwidth'),
      isNameLabelDisabled: element.boolAttribute('noname'),
      controls: List.unmodifiable(element.childElements
          .map((child) => FormFieldControlModel.fromXmlElement(
                child,
                messages: messages,
                conditionalHideConsumer: conditionalStateCheckerConsumer,
              ))),
    );
  }

  bool get isHidden => !controls.any((element) => !element.isHidden);
}

@immutable
class MgrFormSetValuesOptions {
  final bool isTriggeredOnChange,
      isFinal,
      isBlocking,
      isSkippingFiles,
      isPeriodic;
  final Duration? period;

  const MgrFormSetValuesOptions({
    this.isTriggeredOnChange = true,
    this.isFinal = false,
    this.isBlocking = false,
    this.isSkippingFiles = false,
    this.isPeriodic = false,
    this.period,
  });

  static MgrFormSetValuesOptions? fromXmlElement(XmlElement element) {
    final setvalues = element.attribute('setvalues');
    if (setvalues == null) {
      return null;
    }

    switch (setvalues) {
      case 'final':
        return const MgrFormSetValuesOptions(isFinal: true);
      case 'blocking':
        return const MgrFormSetValuesOptions(isBlocking: true);
      case 'finalblock':
        return const MgrFormSetValuesOptions(
          isFinal: true,
          isBlocking: true,
        );
      case 'skipfiles':
        return const MgrFormSetValuesOptions(isSkippingFiles: true);
      default:
        final period = int.tryParse(setvalues);
        return period == null || period == 0
            ? const MgrFormSetValuesOptions()
            : MgrFormSetValuesOptions(
                isTriggeredOnChange: false,
                isPeriodic: true,
                period: Duration(seconds: period),
              );
    }
  }
}

@immutable
class MgrValidatorOptions {
  final String func;
  final String? args;

  const MgrValidatorOptions({required this.func, this.args});

  static MgrValidatorOptions? fromXmlElement(XmlElement element) {
    final check = element.attribute('check');
    if (check == null) {
      return null;
    }

    return MgrValidatorOptions(
      func: check,
      args: element.attribute('checkargs'),
    );
  }
}

@immutable
abstract class FormFieldControlModel {
  final String name;
  final bool isReadonly, isRequired, isFocus;
  final String? convert;
  final MgrFormSetValuesOptions? setValuesOptions;
  final MgrValidatorOptions? validatorOptions;
  late final String? value;

  @protected
  FormFieldControlModel.innerFromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer})
      : name = element.requireAttribute('name'),
        isReadonly = element.boolAttribute('readonly'),
        isRequired = element.boolAttribute('required'),
        isFocus = element.boolAttribute('focus'),
        convert = element.attribute('convert'),
        setValuesOptions = MgrFormSetValuesOptions.fromXmlElement(element),
        validatorOptions = MgrValidatorOptions.fromXmlElement(element) {
    // TODO read readonly and prefix attr for setvalues functionality
    value = extractValue(element);

    List<MgrConditionalStateChecker> ifs = [];
    for (final condition in element.findElements('if')) {
      final empty = condition.attribute('empty');
      final shadow = condition.attribute('shadow');
      final hide = condition.attribute('hide');
      final targetField = shadow ?? hide;
      final targetStatus = shadow != null && shadow.isNotEmpty
          ? MgrFormState.readOnly
          : hide != null && hide.isNotEmpty
              ? MgrFormState.gone
              : MgrFormState.visible;

      MgrConditionalStateChecker? checker;
      if (empty == null) {
        final value = condition.attribute('value');
        if (value == null) {
          // TODO exception
          throw '${condition.positionDescription} may not have no "empty" or "value" attributes';
        }

        checker = (controller) =>
            controller[name] == value ? targetStatus : MgrFormState.visible;
      } else {
        if (condition.attribute('value') != null) {
          // TODO exception
          throw '${condition.positionDescription} may not have both "empty" and "value" attributes';
        }

        switch (empty) {
          case 'yes':
            checker = (controller) => (controller[name] ?? '') == ''
                ? targetStatus
                : MgrFormState.visible;
            break;
          case 'no':
            checker = (controller) => (controller[name] ?? '') == ''
                ? MgrFormState.visible
                : targetStatus;
            break;
          default:
            // TODO exception
            throw '${condition.positionDescription} has invalid "empty" attribute value: "$empty"';
        }
      }

      ifs.add(checker);
      if (conditionalHideConsumer != null &&
          targetField != null &&
          targetStatus != MgrFormState.visible) {
        conditionalHideConsumer(targetField, checker);
      }
    }

    for (final condition in element.findElements('else')) {
      final shadow = condition.attribute('shadow');
      final hide = condition.attribute('hide');
      final targetField = shadow ?? hide;
      final targetStatus = shadow != null && shadow.isNotEmpty
          ? MgrFormState.readOnly
          : hide != null && hide.isNotEmpty
              ? MgrFormState.gone
              : MgrFormState.visible;

      if (conditionalHideConsumer != null &&
          targetField != null &&
          targetStatus != MgrFormState.visible) {
        conditionalHideConsumer(targetField, (controller) {
          for (final item in ifs) {
            if (item(controller) != MgrFormState.visible) {
              return MgrFormState.visible;
            }
          }

          return targetStatus;
        });
      }
    }
  }

  factory FormFieldControlModel.fromXmlElement(XmlElement element,
      {required Map<String, String> messages,
      ConditionalStateCheckerConsumer? conditionalHideConsumer}) {
    switch (element.name.local) {
      case 'input':
        return element.attribute('type') == 'checkbox'
            ? CheckFormFieldControlModel.fromXmlElement(element,
                messages: messages,
                conditionalHideConsumer: conditionalHideConsumer)
            : TextInputFormFieldControlModel.fromXmlElement(element,
                messages: messages,
                conditionalHideConsumer: conditionalHideConsumer);
      case 'select':
        return SelectFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'textarea':
        return TextAreaFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'slider':
        return SliderFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'tree':
        return TreeFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'list':
        return ListFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'htmldata':
        return HtmlDataFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'textdata':
        return TextDataFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'img':
        return ImgFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'desc':
        return DescFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'link':
        return LinkFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'frame':
        return FrameFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'datetime':
        return DateTimeFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'ticket':
        return TicketFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
      case 'captcha':
        return CaptchaFormFieldControlModel.fromXmlElement(element,
            messages: messages,
            conditionalHideConsumer: conditionalHideConsumer);
    }

    throw MgrUnexpectedTagException(element);
  }

  bool get isHidden => false;

  String? extractValue(XmlElement element) => element.document?.rootElement
      .findElements(name)
      .map((e) => e.innerText)
      .joinOrNull(', ');

  void updateController(MgrFormController controller) {}

  Widget build({
    required MgrFormController controller,
    required bool forceReadOnly,
    required MgrExceptionHolder? exceptionHolder,
  }) =>
      Text('unimplemented ${runtimeType.toString()}'); // TODO убрать
}
