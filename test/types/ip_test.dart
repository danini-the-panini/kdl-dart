import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/ip.dart';

void main() {
  test('ipv4', () {
    expect(KdlIPV4.call(KdlString('127.0.0.1')).value, equals('127.0.0.1'));
    expect(KdlIPV4.call(KdlString('192.168.42.255')).value,
        equals('192.168.42.255'));

    expect(() => KdlIPV4.call(KdlString('not an ipv4 address')),
        throwsA(anything));
    expect(() => KdlIPV4.call(KdlString('3ffe:505:2::1')), throwsA(anything));
    expect(() => KdlIPV4.call(KdlString('256.0.0.0')), throwsA(anything));
    expect(() => KdlIPV4.call(KdlString('312.0.0.0')), throwsA(anything));
  });

  test('ipv6', () {
    final addresses = [
      'FEDC:BA98:7654:3210:FEDC:BA98:7654:3210',
      '1080:0:0:0:8:800:200C:417A',
      '1080:0:0:0:8:800:200C:417A',
      'FF01:0:0:0:0:0:0:101',
      '0:0:0:0:0:0:0:1',
      '0:0:0:0:0:0:0:0',
      '1080::8:800:200C:417A',
      'FF01::101',
      '::1',
      '::',
      '0:0:0:0:0:0:13.1.68.3',
      '0:0:0:0:0:FFFF:129.144.52.38',
      '::13.1.68.3',
      '::FFFF:129.144.52.38'
    ];
    for (var addr in addresses) {
      expect(KdlIPV6.call(KdlString(addr)).value, equals(addr));
    }

    expect(() => KdlIPV6.call(KdlString('not an ipv6 address')),
        throwsA(anything));
    expect(() => KdlIPV6.call(KdlString('127.0.0.1')), throwsA(anything));
  });
}
