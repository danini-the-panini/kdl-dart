import 'dart:convert';
import 'dart:typed_data';

import "../document.dart";

/// A Base64-encoded string, denoting arbitrary binary data.
class KdlBase64 extends KdlValue<Uint8List> {
  /// Construct a new `KdlBase64`
  KdlBase64(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlBase64`
  static KdlBase64? convert(KdlValue value, [String type = 'base64']) {
    if (value is! KdlString) return null;

    return KdlBase64(base64.decode(value.value), type);
  }
}
