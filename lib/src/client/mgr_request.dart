import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/extensions/map_extensions.dart';
import 'package:flutter_mgr5/src/client/auth_info.dart';

@immutable
class MgrRequest {
  final Map<String, String> params;

  MgrRequest(Map<String, String> params) : params = Map.unmodifiable(params);

  MgrRequest.func(
    String? func, [
    Map<String, String>? params,
  ]) : params = Map.unmodifiable(func == null
            ? params ?? {}
            : (params?.copyWith(map: {'func': func}) ?? {'func': func}));

  String? get func => params['func'];

  String? get lang => params['lang'];

  MgrRequest copyWith({
    AuthInfo? authInfo,
    Map<String, String>? params,
  }) {
    final copy = Map<String, String>.from(this.params);
    if (params != null) copy.addAll(params);
    authInfo?.intoParams(copy);
    return MgrRequest(copy);
  }
}
