import 'package:flutter/foundation.dart';

/// Type for the list of items used in a select control element.
typedef Slist = List<SlistEntry>;

/// Immutable item used in a select control element.
@immutable
class SlistEntry {
  final String? key, depend;
  final String label;
  late final String _lowercaseLabel = label.toLowerCase();

  SlistEntry(this.key, this.label, this.depend);

  bool containsText(Pattern pattern) => _lowercaseLabel.contains(pattern);
}
