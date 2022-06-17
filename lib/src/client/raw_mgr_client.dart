import 'dart:typed_data';

import 'package:flutter_mgr5/src/client/mgr_request.dart';

abstract class RawMgrClient {
  Future<Uint8List> requestBytes(MgrRequest request);
}
