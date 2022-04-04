import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/mgr5.dart';
import 'package:flutter_mgr5/src/list/mgr_list_model.dart';
import 'package:xml/xml.dart';

class MgrListController {
  MgrClient mgrClient;

  late final MgrListItems items = _MgrListPages(this);
  final String func;
  final Map<String, String>? params;
  final MgrListSelection selection = _MgrListSelection();

  MgrListController({
    required this.mgrClient,
    required this.func,
    this.params,
  });

  void dispose() => items.dispose();
}

abstract class MgrListItems implements Listenable, Iterable<MgrListElem?> {
  int get length;

  MgrListElem? operator [](int index);

  void ingestXmlDocument(XmlDocument doc) => ingestXmlElement(doc.rootElement);

  void ingestXmlElement(XmlElement doc);

  void clear();

  void dispose();

  @deprecated
  void requestFirstPage();
}

abstract class MgrListSelection implements Set<String>, Listenable {}

class _MgrListPages extends IterableBase<MgrListElem?>
    with ChangeNotifier, MgrListItems {
  final MgrListController _controller;
  final Map<int, List<MgrListElem>> _pages = {};
  final Map<int, Future<XmlDocument>> _pageLoadingFutures = {};
  final int _pageSize = 500;

  int _elemCount = 0;

  _MgrListPages(this._controller);

  @override
  int get length => _elemCount;

  @override
  void clear() {
    _pages.clear();
    _pageLoadingFutures.clear();
    notifyListeners();
  }

  @override
  void ingestXmlElement(XmlElement doc) => ingest(
        (int.tryParse(doc.getElement('p_num')?.innerText ?? 'kostil') ?? 1) - 1,
        List.unmodifiable(
          doc.findElements('elem').map((e) => parseElem(e)),
        ),
        (int.tryParse(doc.getElement('p_elems')?.innerText ?? 'kostil') ?? 0),
      );

  void ingest(int index, List<MgrListElem> data, int totalElemCount) {
    if (totalElemCount != _elemCount) {
      _pages.clear();
      _pageLoadingFutures.clear();

      _elemCount = totalElemCount;
    }

    _pages[index] = data;
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
      ingestXmlDocument(doc);
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

class _MgrListSelection extends SetBase<String>
    with MgrListSelection, ChangeNotifier {
  final Set<String> _set = {};

  @override
  bool add(String value) {
    if (_set.add(value)) {
      notifyListeners();
      return true;
    }

    return false;
  }

  @override
  bool contains(Object? element) => _set.contains(element);

  @override
  Iterator<String> get iterator => _set.iterator;

  @override
  int get length => _set.length;

  @override
  String? lookup(Object? element) => _set.lookup(element);

  @override
  bool remove(Object? value) {
    if (_set.remove(value)) {
      notifyListeners();
      return true;
    }

    return false;
  }

  @override
  Set<String> toSet() => _set.toSet();
}
