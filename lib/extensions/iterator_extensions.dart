extension IteratorJoinOrNull<T> on Iterable<T> {
  String? joinOrNull([String separator = '']) =>
      isEmpty ? null : join(separator);
}

extension IteratorWhereNotNull<T> on Iterable<T?> {
  Iterable<T> whereNotNull() =>
      where((element) => element != null).map((e) => e!);
}
