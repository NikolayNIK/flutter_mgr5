import 'package:flutter/material.dart';

/// Type for the list of items used in a select control element.
typedef Slist = List<SlistEntry>;

/// Immutable item used in a select control element.
@immutable
class SlistEntry {
  final String? key, depend;
  final String label;
  final MaterialColor? textColor;
  late final String _lowercaseLabel = label.toLowerCase();

  SlistEntry({
    required this.key,
    required this.label,
    this.depend,
    this.textColor,
  });

  bool containsText(Pattern pattern) => _lowercaseLabel.contains(pattern);
}
