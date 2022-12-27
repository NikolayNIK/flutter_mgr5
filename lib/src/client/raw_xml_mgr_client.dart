import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_mgr5/mgr5_form.dart';
import 'package:flutter_mgr5/mgr5_list.dart';
import 'package:flutter_mgr5/src/client/mgr_request.dart';
import 'package:flutter_mgr5/src/client/raw_mgr_client.dart';
import 'package:flutter_mgr5/src/client/xml_mgr_client.dart';
import 'package:flutter_mgr5/src/mgr_model.dart';
import 'package:xml/xml.dart';

const _offloadThresholdBytes = 4096;

XmlDocument _parseXmlDocument(Uint8List buffer) {
  final doc = XmlDocument.parse(const Utf8Decoder().convert(buffer));
  XmlMgrClient.checkError(doc);
  return doc;
}

Future<MgrModel> _parseXmlDocumentIntoModel(Uint8List buffer) =>
    MgrModel.fromXmlDocument(_parseXmlDocument(buffer));

abstract class RawXmlMgrClient implements XmlMgrClient, RawMgrClient {
  @override
  Future<void> request(MgrRequest request) => requestXmlDocument(request);

  @override
  Future<XmlDocument> requestXmlDocument(MgrRequest request) async {
    final bytes = await requestBytes(request.copyWith(
      authInfo: authInfo,
      params: {'out': 'devel'},
    ));
    try {
      return bytes.length > _offloadThresholdBytes
          ? await compute(_parseXmlDocument, bytes)
          : _parseXmlDocument(bytes);
    } on MgrException catch (e) {
      invalidateIfNeeded(e);
      rethrow;
    }
  }

  @override
  Future<MgrModel> requestModel(MgrRequest request) async {
    final bytes = await requestBytes(request.copyWith(
      authInfo: authInfo,
      params: {'out': 'devel'},
    ));
    try {
      return bytes.length > _offloadThresholdBytes
          ? await compute(_parseXmlDocumentIntoModel, bytes)
          : await _parseXmlDocumentIntoModel(bytes);
    } on MgrException catch (e) {
      invalidateIfNeeded(e);
      rethrow;
    }
  }
}
