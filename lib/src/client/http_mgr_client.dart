import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/src/client/auth_info.dart';
import 'package:flutter_mgr5/src/client/http_raw_mgr_client.dart';
import 'package:flutter_mgr5/src/client/mgr_client.dart';
import 'package:flutter_mgr5/src/client/raw_xml_mgr_client.dart';

class HttpMgrClient
    with HttpRawMgrClient, RawXmlMgrClient, ChangeNotifier, MgrClientMixin {
  @override
  final Uri url;
  @override
  final AuthInfo? authInfo;

  HttpMgrClient(this.url, this.authInfo);
}
