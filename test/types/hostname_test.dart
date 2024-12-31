import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/hostname.dart';

void main() {
  test('hostname', () {
    expect(KdlHostname.call(KdlString('www.example.com'))!.value,
        equals('www.example.com'));

    // 63 a's
    var maxPartLength =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com';
    expect(KdlHostname.call(KdlString(maxPartLength))!.value,
        equals(maxPartLength));

    var maxLength =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    expect(KdlHostname.call(KdlString(maxLength))?.value, equals(maxLength));

    expect(
        () => KdlHostname.call(KdlString('not a hostname')), throwsA(anything));
    expect(() => KdlHostname.call(KdlString('-start-with-a-dash.com')),
        throwsA(anything));
    expect(() => KdlHostname.call(KdlString('a$maxPartLength')),
        throwsA(anything));
    expect(
        () => KdlHostname.call(KdlString('${maxLength}a')), throwsA(anything));
  });

  test('idn hostname', () {
    var value = KdlIDNHostname.call(KdlString('xn--bcher-kva.example'))!;
    expect(value.value, equals('xn--bcher-kva.example'));
    expect(value.unicodeValue, equals('bücher.example'));

    value = KdlIDNHostname.call(KdlString('bücher.example'))!;
    expect(value.value, equals('xn--bcher-kva.example'));
    expect(value.unicodeValue, equals('bücher.example'));

    expect(() => KdlIDNHostname.call(KdlString('not a hostname')),
        throwsA(anything));
  });
}
