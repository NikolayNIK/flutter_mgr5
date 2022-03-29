extension DateTimeToStandardString on DateTime {
  String toStringDateTime() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}'
      ' ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';

  String toStringDate() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
