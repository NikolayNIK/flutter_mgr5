import 'dart:typed_data';

import 'package:flutter_mgr5/src/client/mgr_request.dart';
import 'package:flutter_mgr5/src/client/raw_mgr_client.dart';
import 'package:http/http.dart' as http;

abstract class HttpRawMgrClient implements RawMgrClient {
  Uri get url;

  @override
  Future<Uint8List> requestBytes(MgrRequest request) async =>
      (await http.get(url.replace(queryParameters: request.params),
              headers: {'Referrer': url.toString()}))
          .bodyBytes;
}
