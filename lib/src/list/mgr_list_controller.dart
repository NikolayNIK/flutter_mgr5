import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/client/mgr_client.dart';
import 'package:flutter_mgr5/src/client/mgr_request.dart';
import 'package:flutter_mgr5/src/list/mgr_list_model.dart';

typedef MgrListElemKey = String;

class MgrListController {
  MgrClient mgrClient; // TODO вынести из контроллера

  late final MgrListPages pages = _MgrListPages(this);
  late final MgrListItems items = _MgrListItems(this);
  late final TextEditingController searchTextEditingController =
      _createSearchController();
  late final verticalTableScrollController = ScrollController();
  late final horizontalTableScrollController = ScrollController();
  late final isFilterOpen = ValueNotifier(false);

  final String func;
  final Map<String, String>? params;
  final MgrListSelection selection = _MgrListSelection();
  final rowHeightScale = ValueNotifier<double>(1.0);

  late String _keyField;
  String? _filter;

  MgrListController({
    required this.mgrClient,
    required this.func,
    this.params,
  });

  String? get searchPattern => _filter;

  void update(MgrListModel model) {
    _keyField = model.keyField ?? 'id';
    pages.update(model);
  }

  void dispose() => items.dispose();

  TextEditingController _createSearchController() {
    final controller = TextEditingController();
    controller.addListener(_searchTextChanged);
    return controller;
  }

  void _searchTextChanged() {
    String? value = searchTextEditingController.text.trim().toLowerCase();
    if (value.isEmpty) {
      value = null;
    }

    if (_filter != value) {
      _filter = value;
      pages._search(value);
    }
  }
}

class MgrListPage extends ValueListenable<List<MgrListElem>?>
    with ChangeNotifier {
  final MgrListController _controller;
  final int index;
  final String name;
  final Map<MgrListElemKey, MgrListElem> _keyToElemMap = {};

  List<MgrListElem>? _items, _searchItems;
  bool _isDisposed = false, _isLoading = false;

  MgrListPage(
    this._controller,
    this.index,
    this.name, [
    List<MgrListElem>? items,
  ]);

  bool get loaded => _items != null;

  int get length =>
      _searchItems?.length ?? _items?.length ?? _controller.pages.pageSize;

  @override
  List<MgrListElem>? get value => items;

  List<MgrListElem>? get items {
    final items = _items;
    if (items == null) {
      _load();
    }

    return _searchItems ?? items;
  }

  set items(List<MgrListElem>? items) {
    _items = items;
    _keyToElemMap.clear();
    _search(_controller.searchPattern);
    notifyListeners();
  }

  MgrListElem? findElemByKey(MgrListElemKey key) {
    if (_keyToElemMap.isEmpty) {
      final list = _items;
      if (list != null) {
        for (final elem in list) {
          final key = elem[_controller._keyField];
          if (key != null) {
            _keyToElemMap[key] = elem;
          }
        }
      }
    }

    return _keyToElemMap[key];
  }

  @override
  void dispose() {
    super.dispose();

    _isDisposed = true;
  }

  void _load() async {
    assert(!_isDisposed);

    if (_isLoading) {
      return;
    }

    _isLoading = true;

    try {
      final model = await _controller.mgrClient.requestListModel(
        MgrRequest.func(
          _controller.func,
          (_controller.params ?? {}).copyWith(
            map: {
              'p_num': (index + 1).toString(),
              'p_cnt': _controller.pages.pageSize.toString(),
            },
          ),
        ),
      );

      if (_isDisposed) {
        return;
      }

      _controller.update(model);
    } finally {
      _isLoading = false;
    }
  }

  void _search(String? filter) {
    _searchItems = filter == null || _items == null
        ? _items
        : List.unmodifiable(_items!.where((element) => element.values
            .any((value) => value.toLowerCase().contains(filter))));
  }
}

abstract class MgrListPages implements Listenable, Iterable<MgrListPage> {
  int get pageCount;

  int get itemCount;

  int get loadedItemCount;

  int get pageSize;

  set pageSize(int value);

  MgrListPage operator [](int index);

  MgrListElem? findElemByKey(MgrListElemKey key);

  void update(MgrListModel model);

  void reset();

  void _search(String? filter);
}

abstract class MgrListItems implements Listenable, Iterable<MgrListElem?> {
  int get length;

  int get loadedItemCount;

  MgrListElem? operator [](int index);

  MgrListElem? findElemByKey(MgrListElemKey key);

  void clear();

  void dispose();
}

abstract class MgrListSelection implements Set<MgrListElemKey>, Listenable {}

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
  int get itemCount {
    if (_pages.isEmpty) {
      return _elemCount;
    }

    var count = 0;
    for (final page in _pages) count += page.length;
    return count;
  }

  @override
  int get loadedItemCount {
    if (_pages.isEmpty) {
      return _elemCount;
    }

    var count = 0;
    for (final page in _pages) if (page.loaded) count += page.length;
    return count;
  }

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
    _pages.forEach((page) => page.items = null);
    notifyListeners();
  }

  @override
  MgrListElem? findElemByKey(MgrListElemKey key) {
    for (final page in _controller.pages) {
      final elem = page.findElemByKey(key);
      if (elem != null) {
        return elem;
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
    if (index != null && _pages.isNotEmpty) {
      _pages[index - 1].items = model.pageData;
      notificationRequired = true;
    }

    if (notificationRequired) {
      notifyListeners();
    }
  }

  @override
  void _search(String? filter) {
    for (final page in _pages) {
      page._search(filter);
    }

    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();

    _controller.selection.removeWhere((key) => findElemByKey(key) == null);
  }
}

class _MgrListItems extends IterableBase<MgrListElem?> with MgrListItems {
  final MgrListController _controller;

  _MgrListItems(this._controller);

  @override
  int get length => _controller.pages.itemCount;

  @override
  int get loadedItemCount => _controller.pages.loadedItemCount;

  @override
  void clear() => _controller.pages.reset();

  @override
  MgrListElem? operator [](int index) {
    late final rangeError =
        RangeError('Index $index must be in the range [0..$length).');
    if (index < 0) {
      throw rangeError;
    }

    var runningCount = 0;
    for (final page in _controller.pages) {
      final len = page.length;
      runningCount += len;
      if (runningCount > index) {
        return page.items?[index - runningCount + len];
      }
    }

    throw rangeError;
  }

  @override
  MgrListElem? findElemByKey(MgrListElemKey key) =>
      _controller.pages.findElemByKey(key);

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
