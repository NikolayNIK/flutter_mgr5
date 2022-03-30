import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/src/mgr_exception.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class MgrClient extends ChangeNotifier implements Listenable {
  final Uri _url;
  final String? _login, _password, _lang;

  bool _isInvalidated = false;

  MgrClient(this._url, {String? login, String? password, String? lang})
      : _login = login,
        _password = password,
        _lang = lang {
    _isInvalidated = !isValid;
  }

  get login => _login;

  get password => _password;

  get lang => _lang;

  bool get isValid =>
      !_isInvalidated &&
      (kIsWeb || // на вебе информация о сессии может жить в печеньках
          (_login != null &&
              _login!.isNotEmpty &&
              _password != null &&
              _password!.isNotEmpty &&
              _lang != null &&
              _lang!.isNotEmpty));

  Future<XmlDocument> requestXmlDocument(String? func,
      [Map<String, String>? params]) async {
    params = params == null ? HashMap() : HashMap.of(params);

    if (func != null) params['func'] = func;

    params.putIfAbsent('out', () => 'devel');

    if (_lang != null) params.putIfAbsent('lang', () => _lang!);

    if (_login != null && _password != null) {
      params.putIfAbsent('authinfo', () => _login! + ':' + _password!);
    }

    final uri = _url.replace(queryParameters: params);
    final response =
        await http.get(uri, headers: {'Referrer': _url.toString()});
    XmlDocument doc =
        XmlDocument.parse(const Utf8Decoder().convert(response.bodyBytes));
    _checkError(doc);
    if (doc.rootElement.childElements
        .any((element) => element.name.local == 'loginform')) {
      _invalidate();
    }

    return doc;
  }

  void _checkError(XmlDocument doc) {
    final error = doc.rootElement.child('error');
    if (error != null) {
      final exception = MgrException.fromElement(error);
      if (exception.type == 'auth') _invalidate();

      throw exception;
    }
  }

  Future<bool> validate() async {
    if (!isValid) return false;

    await requestXmlDocument('whoami');

    return true;
  }

  void _invalidate() {
    if (!_isInvalidated) {
      _isInvalidated = true;
      notifyListeners();
    }
  }
}
