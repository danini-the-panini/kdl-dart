import 'dart:convert';
import 'dart:typed_data';

import "../document.dart";

class KdlBase64 extends KdlValue<Uint8List> {
  KdlBase64(Uint8List value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'base64']) {
    if (!(value is KdlString)) return null;

    return KdlBase64(base64.decode(value.value), type);
  }
}
