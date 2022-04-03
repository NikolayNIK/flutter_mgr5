extension IteratorJoinOrNull<T> on Iterable<T> {
  String? joinOrNull([String separator = '']) =>
      isEmpty ? null : join(separator);
}

extension IteratorWhereNotNull<T> on Iterable<T?> {
  Iterable<T> whereNotNull() =>
      where((element) => element != null).map((e) => e!);
}

extension IteratorMaybe<T> on Iterable<T> {
  T? get maybeSingle {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }

    final value = iterator.current;
    if (iterator.moveNext()) {
      return null;
    }

    return value;
  }

  T? get maybeFirst {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }

    return iterator.current;
  }
}
