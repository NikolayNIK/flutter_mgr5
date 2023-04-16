import 'dart:collection';

import 'package:flutter/foundation.dart';

class ListenableSet<T> with SetMixin<T>, ChangeNotifier {
  final Set<T> _impl;

  ListenableSet([Set<T>? set]) : _impl = set ?? {};

  @override
  bool add(T value) {
    final result = _impl.add(value);
    notifyListeners();
    return result;
  }

  @override
  bool contains(Object? element) => _impl.contains(element);

  @override
  Iterator<T> get iterator => _impl.iterator;

  @override
  int get length => _impl.length;

  @override
  T? lookup(Object? element) => _impl.lookup(element);

  @override
  bool remove(Object? value) {
    final result = _impl.remove(value);
    notifyListeners();
    return result;
  }

  @override
  Set<T> toSet() => _impl.toSet();

  @override
  void clear() {
    _impl.clear();
    notifyListeners();
  }
}
