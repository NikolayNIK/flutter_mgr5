extension MapCopyWith<K, V> on Map<K, V> {
  Map<K, V> copyWith({Iterable<MapEntry<K, V>>? entries, Map<K, V>? map}) => {
        for (final entry in this.entries) entry.key: entry.value,
        if (entries != null)
          for (final entry in entries) entry.key: entry.value,
        if (map != null)
          for (final entry in map.entries) entry.key: entry.value,
      };
}
