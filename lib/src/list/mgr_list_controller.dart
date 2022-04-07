import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/list/mgr_list_model.dart';
import 'package:xml/xml.dart';

typedef MgrListElemKey = String;

class MgrListController {
  MgrClient mgrClient;

  late final MgrListItems items = _MgrListItems(this);
  final String func;
  final Map<String, String>? params;
  final MgrListSelection selection = _MgrListSelection();

  MgrListController({
    required this.mgrClient,
    required this.func,
    this.params,
  });

  void update(MgrListModel model) {
    items.update(model);
  }

  void dispose() => items.dispose();
}

abstract class MgrListItems implements Listenable, Iterable<MgrListElem?> {
  int get length;

  MgrListElem? operator [](int index);

  void update(MgrListModel model);

  void clear();

  void dispose();

  @deprecated
  void requestFirstPage();
}

abstract class MgrListSelection implements Set<MgrListElemKey>, Listenable {}

class _MgrListItems extends IterableBase<MgrListElem?>
    with ChangeNotifier, MgrListItems {
  final MgrListController _controller;
  final Map<int, List<MgrListElem>> _pages = {};
  final Map<int, Future<XmlDocument>> _pageLoadingFutures = {};
  final int _pageSize = 500;

  int _elemCount = 0;

  _MgrListItems(this._controller);

  @override
  int get length => _elemCount;

  @override
  void clear() {
    _pages.clear();
    _pageLoadingFutures.clear();
    notifyListeners();
  }

  @override
  MgrListElem? operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError('Index $index must be in the range [0..$length).');
    }

    final pageIndex = (index / _pageSize).floor();
    final elemIndex = index % _pageSize;
    final page = _pages[pageIndex];
    if (page == null) {
      _requestPage(pageIndex);
      return null;
    }

    return page[elemIndex];
  }

  @override
  void update(MgrListModel model) {
    var notificationRequired = false;
    if (model.elemCount != _elemCount) {
      _pages.clear();
      _pageLoadingFutures.clear();

      _elemCount = model.elemCount ?? 0;
      notificationRequired = true;
    }

    final index = model.pageIndex;
    if (index != null) {
      _pages[index] = model.pageData;
      notificationRequired = true;
    }

    if (notificationRequired) {
      notifyListeners();
    }
  }

  void _requestPage(int pageIndex) async {
    Future<XmlDocument>? future;

    final doc = await _pageLoadingFutures.putIfAbsent(
      pageIndex,
      () => future = _controller.mgrClient.requestXmlDocument(
        _controller.func,
        (_controller.params ?? {}).copyWith(
          map: {
            'p_num': (pageIndex + 1).toString(),
            'p_cnt': _pageSize.toString(),
          },
        ),
      ),
    );

    if (future != null && _pageLoadingFutures[pageIndex] == future) {
      update(MgrListModel.fromXmlDocument(doc));
      _pageLoadingFutures.remove(pageIndex);
    }
  }

  @override
  void requestFirstPage() {
    _requestPage(0);
  }

  @override
  Iterator<MgrListElem?> get iterator =>
      Iterable.generate(length).map((e) => this[e]).iterator;
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
