import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/list/mgr_list_model.dart';

typedef MgrListElemKey = String;

class MgrListController {
  MgrClient mgrClient; // TODO вынести из контроллера

  late final MgrListItemKeys itemKeys = _MgrListItemKeys();
  late final MgrListPages pages = _MgrListPages(this);
  late final MgrListItems items = _MgrListItems(this);
  final String func;
  final Map<String, String>? params;
  final MgrListSelection selection = _MgrListSelection();
  final rowHeightScale = ValueNotifier<double>(1.0);

  late String _keyField;

  MgrListController({
    required this.mgrClient,
    required this.func,
    this.params,
  });

  void update(MgrListModel model) {
    _keyField = model.keyField ?? 'id';
    pages.update(model);
  }

  void dispose() => items.dispose();
}

class MgrListPage extends ValueNotifier<List<MgrListElem>?> {
  final MgrListController _controller;
  final int index;
  final String name;
  final Map<MgrListElemKey, int> _keyToPositionMap = {};

  bool _isDisposed = false, _isLoading = false;

  MgrListPage(
    this._controller,
    this.index,
    this.name, [
    List<MgrListElem>? items,
  ]) : super(items);

  List<MgrListElem>? get items => value;

  set items(List<MgrListElem>? items) => value = items;

  @override
  List<MgrListElem>? get value {
    final items = super.value;
    if (items == null) {
      _load();
    }

    return items;
  }

  int? findPositionByKey(MgrListElemKey key) => _keyToPositionMap[key];

  @override
  void notifyListeners() {
    super.notifyListeners();

    _keyToPositionMap.clear();
    final list = value;
    if (list != null) {
      var i = 0;
      for (final elem in list) {
        final key = elem[_controller._keyField];
        if (key != null) {
          _keyToPositionMap[key] = i++;
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _load() async {
    assert(!_isDisposed);

    if (_isLoading) {
      return;
    }

    print('loading page $index');

    _isLoading = true;

    try {
      final doc = await _controller.mgrClient.requestXmlDocument(
        _controller.func,
        (_controller.params ?? {}).copyWith(
          map: {
            'p_num': (index + 1).toString(),
            'p_cnt': _controller.pages.pageSize.toString(),
          },
        ),
      );

      if (_isDisposed) {
        return;
      }

      _controller.update(MgrListModel.fromXmlDocument(doc));
    } finally {
      _isLoading = false;
    }
  }
}

abstract class MgrListPages implements Listenable, Iterable<MgrListPage> {
  int get pageCount;

  int get itemCount;

  int get pageSize;

  set pageSize(int value);

  MgrListPage operator [](int index);

  int? findPositionByKey(MgrListElemKey key);

  void update(MgrListModel model);

  void reset();
}

abstract class MgrListItems implements Listenable, Iterable<MgrListElem?> {
  int get length;

  MgrListElem? operator [](int index);

  int? findPositionByKey(MgrListElemKey key);

  void clear();

  void dispose();
}

abstract class MgrListSelection implements Set<MgrListElemKey>, Listenable {}

abstract class MgrListItemKeys {
  Key operator [](MgrListElemKey key);
}

class _MgrListPages extends MgrListPages
    with IterableMixin<MgrListPage>, ChangeNotifier {
  final MgrListController _controller;
  final List<MgrListPage> _pages = [];

  int _pageSize = 500;
  int _elemCount = 0;

  _MgrListPages(this._controller);

  @override
  int get pageCount => _pages.length;

  @override
  int get itemCount => _elemCount;

  @override
  int get pageSize => _pageSize;

  @override
  set pageSize(int value) {
    if (value != _pageSize) {
      _pageSize = value;
      reset();
    }
  }

  @override
  MgrListPage operator [](int index) => _pages[index];

  @override
  void reset() {
    _pages.forEach((page) => page.value = null);
    notifyListeners();
  }

  @override
  int? findPositionByKey(MgrListElemKey key) {
    var offset = 0;
    for (var i = 0; i < _controller.pages.pageCount; i++) {
      final page = _controller.pages[i];
      final position = page.findPositionByKey(key);
      if (position == null) {
        offset += page.items?.length ?? _controller.pages.pageSize;
      } else {
        return offset + position;
      }
    }

    return null;
  }

  @override
  Iterator<MgrListPage> get iterator => _pages.iterator;

  @override
  void update(MgrListModel model) {
    var notificationRequired = false;
    if (model.elemCount != _elemCount ||
        _pages.length != model.pageNames.length) {
      _pages.clear();
      for (var i = 0; i < model.pageNames.length; i++)
        _pages.add(MgrListPage(_controller, i, model.pageNames[i]));
      _elemCount = model.elemCount ?? 0;
      notificationRequired = true;
    }

    final index = model.pageIndex;
    if (index != null) {
      _pages[index - 1].items = model.pageData;
      notificationRequired = true;
    }

    if (notificationRequired) {
      notifyListeners();
    }
  }
}

class _MgrListItems extends IterableBase<MgrListElem?> with MgrListItems {
  final MgrListController _controller;

  _MgrListItems(this._controller);

  @override
  int get length => _controller.pages.itemCount;

  @override
  void clear() => _controller.pages.reset();

  @override
  MgrListElem? operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError('Index $index must be in the range [0..$length).');
    }

    final pageIndex = (index / _controller.pages.pageSize).floor();
    final elemIndex = index % _controller.pages.pageSize;
    final page = _controller.pages[pageIndex];
    final items = page.value;
    return items == null ? null : items[elemIndex];
  }

  @override
  int? findPositionByKey(MgrListElemKey key) =>
      _controller.pages.findPositionByKey(key);

  @override
  Iterator<MgrListElem?> get iterator =>
      Iterable.generate(length).map((e) => this[e]).iterator;

  @override
  void addListener(VoidCallback listener) =>
      _controller.pages.addListener(listener);

  @override
  void dispose() {}

  @override
  void removeListener(VoidCallback listener) =>
      _controller.pages.removeListener(listener);
}

class _MgrListSelection extends SetBase<MgrListElemKey>
    with MgrListSelection, ChangeNotifier {
  final Set<MgrListElemKey> _set = {};

  @override
  bool add(MgrListElemKey value) {
    if (_set.add(value)) {
      notifyListeners();
      return true;
    }

    return false;
  }

  @override
  bool contains(Object? element) => _set.contains(element);

  @override
  Iterator<MgrListElemKey> get iterator => _set.iterator;

  @override
  int get length => _set.length;

  @override
  MgrListElemKey? lookup(Object? element) => _set.lookup(element);

  @override
  bool remove(Object? value) {
    if (_set.remove(value)) {
      notifyListeners();
      return true;
    }

    return false;
  }

  @override
  Set<MgrListElemKey> toSet() => _set.toSet();
}

class _MgrListItemKeys implements MgrListItemKeys {
  final _map = <MgrListElemKey, Key>{};

  @override
  Key operator [](MgrListElemKey key) =>
      _map.putIfAbsent(key, () => GlobalKey());
}
