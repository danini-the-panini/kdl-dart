import 'dart:convert';

import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/base64.dart';

void main() {
  test('base64', () {
    expect(KdlBase64.call(KdlString('U2VuZCByZWluZm9yY2VtZW50cw=='))!.value,
      equals(utf8.encode('Send reinforcements')));

    expect(() => KdlBase64.call(KdlString('not base64')), throwsA(anything));
  });
}
