import 'package:flutter/widgets.dart';
import 'package:flutter_mgr5/extensions/xml_extensions.dart';
import 'package:flutter_mgr5/mgr5_form.dart';
import 'package:flutter_mgr5/src/client/mgr_client.dart';
import 'package:flutter_mgr5/src/client/mgr_request.dart';
import 'package:flutter_mgr5/src/list/mgr_list_model.dart';
import 'package:flutter_mgr5/src/mgr_model.dart';
import 'package:xml/xml.dart';

abstract class XmlMgrClient implements MgrClient {
  Future<XmlDocument> requestXmlDocument(MgrRequest request);

  @override
  Future<void> request(MgrRequest request) => requestXmlDocument(request);

  @override
  Future<MgrModel> requestModel(MgrRequest request) async =>
      MgrModel.fromXmlDocument(await requestXmlDocument(request));

  static void checkError(XmlDocument doc) {
    final error = doc.rootElement.child('error');
    if (error != null) {
      throw MgrException.fromElement(error);
    }
  }
}
