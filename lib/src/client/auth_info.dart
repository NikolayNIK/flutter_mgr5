abstract class AuthInfo {
  final String? _lang;

  AuthInfo([this._lang]);

  bool get isValid;

  String? get lang => _lang;

  void intoParams(Map<String, String> params) {
    final lang = _lang;
    if (lang != null) params['lang'] = lang;
  }
}
