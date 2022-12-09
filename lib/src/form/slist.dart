import 'package:flutter/foundation.dart';

typedef Slist = List<SlistEntry>;

@immutable
class SlistEntry {
  final String? key, depend;
  final String label;
  late final String _lowercaseLabel = label.toLowerCase();

  SlistEntry(this.key, this.label, this.depend);

  bool containsText(Pattern pattern) => _lowercaseLabel.contains(pattern);
}
