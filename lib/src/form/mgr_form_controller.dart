import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/datetime_extensions.dart';
import 'package:flutter_mgr5/extensions/iterator_extensions.dart';
import 'package:flutter_mgr5/src/form/components/mgr_form_select.dart';
import 'package:flutter_mgr5/src/form/mgr_form_model.dart';
import 'package:flutter_mgr5/src/form/slist.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';

/// Represents all parameters of the form as a string to string Map.
/// Doesn't hold any data by itself. Uses a corresponding controllers
/// MgrFormControllerParamMap to retrieve and set values.
abstract class MgrFormControllerStringParamMap implements Map<String, String> {
  @override
  void operator []=(String key, String? value);
}

/// Container holding all the values of the forms fields.
abstract class MgrFormControllerParamMap
    implements Map<String, MgrFormControllerParam> {
  /// Retrieve a representation of a forms parameter with a given name.
  /// It is guaranteed that returning object never gets switched out
  /// making it safe to add listeners to track parameters changes.
  @override
  MgrFormControllerParam operator [](covariant Object key);

  void set(MgrFormModel model);

  bool check(MgrFormModel model);
}

/// Container holding all the items used in a select control element.
abstract class MgrFormSlistMap implements Map<String, ValueNotifier<Slist>> {
  /// Retrieve a holder for the slist with a given name.
  /// It is guaranteed that returning object never gets switched out
  /// making it safe to add listeners to track slist changes.
  @override
  ValueNotifier<Slist> operator [](covariant Object key);

  void set(MgrFormModel model);

  void _notifyChanged();
}

typedef MgrFormPagesControllerCallback = void Function(
  String pageName,
  MgrFormPageController controller,
);

/// Container holding all the state of a forms pages.
abstract class MgrFormPagesController {
  /// Retrieve a controller for the page with a given name.
  /// It is guaranteed that returning object never gets switched out
  /// making it safe to add listeners to track slist changes.
  MgrFormPageController operator [](String? name);

  void addCallback(MgrFormPagesControllerCallback callback);

  void removeCallback(MgrFormPagesControllerCallback callback);

  void dispose();
}

/// Container holding all the state of a forms page.
class MgrFormPageController extends ValueNotifier<bool> {
  MgrFormPageController(bool isExtended) : super(isExtended);

  void expand() => value = true;

  void collapse() => value = false;

  void toggle() => value = !value;
}

/// MgrFormControllerStringParamMap implementation.
/// Either needs get moved outta here or get merged into the super.
class _MgrFormControllerStringParamMap extends MapBase<String, String>
    implements MgrFormControllerStringParamMap {
  final MgrFormController _controller;

  _MgrFormControllerStringParamMap(this._controller);

  @override
  String? operator [](Object? key) =>
      key == null ? null : _controller.params[key].value;

  @override
  void operator []=(String key, String? value) =>
      _controller.params[key].value = value;

  @override
  void clear() => _controller.params.clear();

  @override
  Iterable<String> get keys => _controller.params.entries
      .where((element) => element.value.value != null)
      .map((e) => e.key);

  @override
  Iterable<String> get values =>
      _controller.params.values.map((e) => e.value).whereNotNull();

  @override
  String? remove(Object? key) => _controller.params.remove(key)?.value;
}

/// MgrFormControllerParamMap implementation.
/// Either needs get moved outta here or get merged into the super.
class _MgrFormControllerParamMap extends MapBase<String, MgrFormControllerParam>
    implements MgrFormControllerParamMap {
  final MgrFormController _controller;
  final Map<String, MgrFormControllerParam> _map = {};

  _MgrFormControllerParamMap(this._controller);

  @override
  Iterable<String> get keys => _map.keys;

  @override
  Iterable<MgrFormControllerParam> get values => _map.values;

  @override
  MgrFormControllerParam operator [](covariant Object key) {
    final name = key.toString();
    return _map.putIfAbsent(
        name,
        () => MgrFormControllerParam(name, _controller)
          ..addListener(() => _controller._notifyChanged(name)));
  }

  @override
  void operator []=(String key, MgrFormControllerParam value) {
    _map[key]?.dispose();
    _map[key] = value;
  }

  @override
  void clear() => _map.values.forEach((element) => element.value = null);

  @override
  MgrFormControllerParam? remove(Object? key) => _map.remove(key)?..dispose();

  @override
  void set(MgrFormModel model) {
    for (final control in model.pages
        .expand((element) => element.fields)
        .expand((element) => element.controls)) {
      if (control.value != null) {
        final param = this[control.name];
        if (param.value == null && control.isFocus) {
          param.focusNode.requestFocus();
        }

        param.value = control.value;
      }
    }

    if (model.elid != null) this['elid'].value = model.elid!;
    if (model.plid != null) this['plid'].value = model.plid!;
  }

  @override
  bool check(MgrFormModel model) {
    for (final page in model.pages) {
      for (final field in page.fields) {
        for (final control in field.controls) {
          if (control.isRequired) {
            final param = this[control.name];
            final value = param.value;
            if ((value == null || value.isEmpty) &&
                model.getStateChecker(field.name)(_controller.stringParams) ==
                    MgrFormState.visible &&
                (page.name == null ||
                    model.getStateChecker(page.name!)(
                            _controller.stringParams) ==
                        MgrFormState.visible)) {
              param.focusNode.requestFocus();
              _controller.exception.value = MgrException('empty', control.name,
                  null, 'Поле не может быть пустым'); // TODO локализация
              return false;
            }
          }
        }
      }
    }

    return true;
  }
}

/// MgrFormSlistMap implementation.
/// Either needs get moved outta here or get merged into the super.
class _MgrFormSlistMap extends MapBase<String, ValueNotifier<Slist>>
    implements MgrFormSlistMap {
  final MgrFormController controller;
  final Map<String, ValueNotifier<Slist>> _original = {}, _filtered = {};
  final Map<String, String> _dependencies = {}; // dependant => dependency
  final Slist _emptySlist = List.unmodifiable(
    [SlistEntry(null, '-- не указано --', null)],
  ); // TODO localize

  _MgrFormSlistMap(this.controller);

  @override
  ValueNotifier<Slist> operator [](covariant Object key) {
    final targetMap = _dependencies.containsKey(key) ? _filtered : _original;
    return targetMap.putIfAbsent(
        key.toString(), () => ValueNotifier(_emptySlist));
  }

  @override
  void operator []=(String key, ValueNotifier<Slist> value) {
    _filtered.remove(key)?.dispose();
    _original[key]?.dispose();
    _original[key] = value;
  }

  @override
  void clear() {
    for (final map in [_filtered, _original]) {
      map.forEach((key, value) => value.dispose());
      map.clear();
    }
  }

  @override
  Iterable<String> get keys => {
        ..._original.keys,
        ..._filtered.keys,
      };

  @override
  Iterable<ValueNotifier<Slist>> get values {
    final filteredKeys = {..._filtered.keys};
    return [
      ..._original.entries
          .where((element) => !filteredKeys.contains(element.key))
          .map((e) => e.value),
      ..._filtered.values,
    ];
  }

  @override
  ValueNotifier<Slist>? remove(Object? key) {
    final filtered = _filtered.remove(key)?..dispose();
    final original = _original.remove(key)?..dispose();
    return filtered ?? original;
  }

  @override
  void set(MgrFormModel model) {
    bool isChanged = false;
    for (final slist in model.slists.entries) {
      isChanged = true;
      _original.putIfAbsent(slist.key, () => ValueNotifier(_emptySlist)).value =
          slist.value;
    }

    for (final control in model.pages
        .expand((element) => element.fields)
        .expand((element) => element.controls)
        .whereType<SelectFormFieldControlModel>()) {
      final depend = control.depend;
      if (depend == null) {
        /*
         // на setvalues depend почему-то обрезается,
         // поэтому зависимости не удаляем
        if (_dependencies.remove(control.name) != null) {
          isChanged = true;
        }*/
      } else {
        if (_dependencies[control.name] != depend) {
          _dependencies[control.name] = depend;
          isChanged = true;
        }
      }
    }

    if (isChanged) {
      _notifyChanged();
    }
  }

  @override
  void _notifyChanged() {
    for (final dependency in _dependencies.entries) {
      final original = _original[dependency.key]?.value;
      final value = controller.stringParams[dependency.value];
      final filteredItems = original == null
          ? _emptySlist
          : List<SlistEntry>.unmodifiable(original.where(
              (element) => element.depend == null || element.depend == value));
      final filteredSlist = filteredItems.isEmpty ? _emptySlist : filteredItems;

      _filtered
          .putIfAbsent(dependency.key, () => ValueNotifier(filteredSlist))
          .value = filteredSlist;
    }
  }
}

/// MgrFormPagesController implementation.
/// Either needs get moved outta here or get merged into the super.
class _MgrFormPageController extends MgrFormPagesController {
  final _map = <String, MgrFormPageController>{};
  final _callbacks = <MgrFormPagesControllerCallback>{};
  final _default = MgrFormPageController(true);

  @override
  MgrFormPageController operator [](String? name) {
    if (name == null) {
      return _default;
    }

    final current = _map[name];
    if (current != null) {
      return current;
    }

    final newController = _map[name] = MgrFormPageController(true);
    for (final callback in _callbacks) {
      callback(name, newController);
    }

    return newController;
  }

  @override
  void addCallback(MgrFormPagesControllerCallback callback) {
    for (final entry in _map.entries) {
      callback(entry.key, entry.value);
    }

    _callbacks.add(callback);
  }

  @override
  void removeCallback(MgrFormPagesControllerCallback callback) =>
      _callbacks.remove(callback);

  @override
  void dispose() => _callbacks.clear();
}

/// Controller for a framework form holding all the mutable state required.
class MgrFormController with ChangeNotifier implements Listenable {
  /// Holds all the values of the forms fields.
  late final MgrFormControllerParamMap params =
      _MgrFormControllerParamMap(this);

  /// String to string dictionary representation of params.
  late final MgrFormControllerStringParamMap stringParams =
      _MgrFormControllerStringParamMap(this);

  /// Holds all the item lists for "select" control elements.
  late final MgrFormSlistMap slists = _MgrFormSlistMap(this);

  /// Holds all the state of forms pages.
  final MgrFormPagesController pages = _MgrFormPageController();

  /// Holds scrolling state of the form.
  late final ScrollController scrollController = ScrollController();

  /// Holds latest exception to be displayed to a user.
  final ValueNotifier<MgrException?> exception = ValueNotifier(null);

  MgrFormController(MgrFormModel model) {
    update(model);

    for (final control in model.pages
        .expand((page) => page.fields)
        .expand((field) => field.controls)) {
      control.updateController(this);
    }

    model.pages
        .where((page) => page.isCollapsed)
        .map((page) => page.name)
        .whereNotNull()
        .forEach((name) => pages[name].collapse());
  }

  void update(MgrFormModel model) {
    slists.set(model);
    params.set(model);
  }

  @override
  void dispose() {
    super.dispose();

    params.clear();
    slists.clear();
    scrollController.dispose();
  }

  void _notifyChanged(String? name) {
    slists._notifyChanged();

    exception.value = null;

    notifyListeners();
  }
}

/// Represents a single value of the form.
/// Actual value is stored in a specific controller that gets converted to
/// a required type as needed keeping the original value if new controller
/// permits it.
class MgrFormControllerParam
    with ChangeNotifier
    implements ValueListenable<String?> {
  /// Field name.
  final String name;

  /// FocusNode for the control widget.
  late final FocusNode focusNode = FocusNode();
  final MgrFormController _formController;
  _MgrFormControlController? _controller;

  MgrFormControllerParam(this.name, this._formController);

  /// Retrieves parameter value from the underlying controller.
  @override
  String? get value => _controller?.value;

  /// Set the value of an underlying controller.
  set value(String? value) {
    _controller ??=
        _getController(() => _ValueMgrFormControlElementController(this));
    _controller!.value = value;
  }

  /// Retrieves underlying controller as MgrTextInputController
  /// converting it if needed.
  MgrTextInputController get textInputController =>
      _getController(() => MgrTextInputController(this));

  /// Retrieves underlying controller as MgrCheckBoxController
  /// converting it if needed.
  MgrCheckBoxController get checkBoxController =>
      _getController(() => MgrCheckBoxController(this));

  /// Retrieves underlying controller as MgrSingleSelectController
  /// converting it if needed.
  MgrSingleSelectController get singleSelectController => _getController(
      () => MgrSingleSelectController(this, _formController.slists[name]));

  /// Retrieves underlying controller as MgrDatetimeController
  /// converting it if needed.
  MgrDatetimeController get datetimeController =>
      _getController(() => MgrDatetimeController(this));

  T _getController<T extends _MgrFormControlController>(T Function() creator) {
    final currentController = _controller;
    if (currentController is T) {
      return currentController;
    }

    currentController?.dispose();
    final newController = creator();
    newController.value = value;
    newController.addListener(notifyListeners);
    _controller = newController;
    return newController;
  }
}

/// Represents an underlying controller of a forms parameter.
abstract class _MgrFormControlController implements ValueListenable<String?> {
  @Deprecated('Use MgrFormControllerParam.focusNode instead')
  FocusNode get focusNode; // можно было бы и убрать

  /// Retrieve a value of the controller converted to string representation.
  @override
  String? get value;

  /// Set a value of the controller or reset if it's not permitted.
  set value(String? value);

  void dispose();
}

/// Controller meant to hold a string value assigned when a control-specific
/// controller type is unknown.
class _ValueMgrFormControlElementController extends ValueNotifier<String?>
    with _MgrFormControlController {
  final MgrFormControllerParam param;

  _ValueMgrFormControlElementController(this.param, [String? value])
      : super(value);

  @override
  FocusNode get focusNode => param.focusNode;
}

/// Controller for a text input control element.
class MgrTextInputController extends _MgrFormControlController {
  final MgrFormControllerParam param;
  final ValueNotifier<String> _container = ValueNotifier('');
  final TextEditingController textEditingController;

  MgrTextInputController(this.param, [String? initialValue])
      : textEditingController = TextEditingController(text: initialValue) {
    focusNode.addListener(() => _container.value = textEditingController.text);
  }

  bool get isChanged => _container.value != textEditingController.text;

  @override
  FocusNode get focusNode => param.focusNode;

  @override
  String get value => textEditingController.text;

  @override
  set value(String? value) {
    final val = value ?? '';
    textEditingController.text = val;
    _container.value = val;
  }

  @override
  void addListener(VoidCallback listener) => _container.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _container.removeListener(listener);

  @override
  void dispose() {
    _container.dispose();
    textEditingController.dispose();
  }
}

/// Controller for a checkbox control element.
/// Holds binary state (true/false) converting to a string value as 'on' or 'off'
/// as required by the API.
class MgrCheckBoxController extends _MgrFormControlController {
  final MgrFormControllerParam param;
  final ValueNotifier<bool> container;

  MgrCheckBoxController(this.param, [String? initialValue])
      : container = ValueNotifier(initialValue == 'on');

  @override
  FocusNode get focusNode => param.focusNode;

  @override
  String get value => container.value ? 'on' : 'off';

  @override
  set value(String? value) => container.value = value == 'on';

  @override
  void addListener(VoidCallback listener) => container.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      container.removeListener(listener);

  @override
  void dispose() => container.dispose();
}

/// Controller for a single selection control element.
/// Holds a key of a selected item from a corresponding slist.
class MgrSingleSelectController extends _MgrFormControlController {
  final MgrFormControllerParam _param;
  final ValueNotifier<String?> _container;
  final ValueListenable<Slist> _slist;
  late int _valueIndex;
  int? _longestLabelLength;

  MgrSingleSelectController(this._param, this._slist, [String? initialValue])
      : _container = ValueNotifier(null) {
    value = initialValue;

    // вызов сеттера для проверки наличия значения в измененном slist'е
    _slist.addListener(() {
      value = value;
      _longestLabelLength = null;
    });
  }

  @override
  FocusNode get focusNode => _param.focusNode;

  ValueListenable<Slist> get slist => _slist;

  @override
  String? get value => _container.value;

  @override
  set value(String? value) {
    final slist = _slist.value;
    for (var i = 0; i < slist.length; i++) {
      final entry = slist[i];
      if (entry.key == value) {
        _container.value = entry.key;
        _valueIndex = i;
        return;
      }
    }

    _container.value = _slist.value.first.key;
    _valueIndex = 0;
  }

  int get valueIndex => _valueIndex;

  set valueIndex(int index) {
    _container.value = _slist.value[index].key;
    _valueIndex = index;
  }

  int get longestLabelLength {
    if (_longestLabelLength != null) {
      return _longestLabelLength!;
    }

    return _longestLabelLength = _slist.value.fold<int>(
      0,
      (previousValue, element) => max(previousValue, element.label.length),
    );
  }

  @override
  void addListener(VoidCallback listener) => _container.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _container.removeListener(listener);

  @override
  void dispose() => _container.dispose();
}

/// Controller for a datetime control element.
class MgrDatetimeController extends _MgrFormControlController {
  final MgrFormControllerParam _param;
  final _container = ValueNotifier<String?>(null);

  DateTime? _value, _setAt;
  bool _isDisposed = false;

  MgrDatetimeController(this._param) {
    Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        _update();
      },
    );
  }

  @override
  FocusNode get focusNode => _param.focusNode;

  @override
  String? get value => _container.value;

  @override
  set value(String? value) {
    _setAt = DateTime.now();
    _value = value == null ? null : DateTime.tryParse(value);
    _update();
  }

  @override
  void addListener(VoidCallback listener) => _container.addListener(listener);

  @override
  void dispose() {
    _isDisposed = true;
    _container.dispose();
  }

  @override
  void removeListener(VoidCallback listener) =>
      _container.removeListener(listener);

  void _update() => _container.value = (_value == null || _setAt == null
          ? DateTime.now()
          : DateTime.now().add((_value!).difference(_setAt!)))
      .toStringDateTime();
}
