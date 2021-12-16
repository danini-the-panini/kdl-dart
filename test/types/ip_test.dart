import 'dart:io';
import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/ip.dart';

void main() {
  test('ipv4', () {
    expect(KdlIPV4.call(KdlString('127.0.0.1')).value,
      equals(InternetAddress('127.0.0.1')));

    expect(() => KdlIPV4.call(KdlString('not an ipv4 address')), throwsA(anything));
    expect(() => KdlIPV4.call(KdlString('3ffe:505:2::1')), throwsA(anything));
  });

  test('ipv6', () {
    expect(KdlIPV6.call(KdlString('::')).value,
      equals(InternetAddress('::')));
    expect(KdlIPV6.call(KdlString('3ffe:505:2::1')).value,
      equals(InternetAddress('3ffe:505:2::1')));

    expect(() => KdlIPV6.call(KdlString('not an ipv4 address')), throwsA(anything));
    expect(() => KdlIPV6.call(KdlString('127.0.0.1')), throwsA(anything));
  });
}
