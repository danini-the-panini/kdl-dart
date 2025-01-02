import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/hostname.dart';

void main() {
  test('hostname', () {
    expect(KdlHostname.convert(KdlString('www.example.com'))!.value,
        equals('www.example.com'));

    // 63 a's
    var maxPartLength =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com';
    expect(KdlHostname.convert(KdlString(maxPartLength))!.value,
        equals(maxPartLength));

    var maxLength =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    expect(KdlHostname.convert(KdlString(maxLength))?.value, equals(maxLength));

    expect(
        () => KdlHostname.convert(KdlString('not a hostname')), throwsA(anything));
    expect(() => KdlHostname.convert(KdlString('-start-with-a-dash.com')),
        throwsA(anything));
    expect(() => KdlHostname.convert(KdlString('a$maxPartLength')),
        throwsA(anything));
    expect(
        () => KdlHostname.convert(KdlString('${maxLength}a')), throwsA(anything));
  });

  test('idn hostname', () {
    var value = KdlIdnHostname.convert(KdlString('xn--bcher-kva.example'))!;
    expect(value.value, equals('xn--bcher-kva.example'));
    expect(value.unicodeValue, equals('bücher.example'));

    value = KdlIdnHostname.convert(KdlString('bücher.example'))!;
    expect(value.value, equals('xn--bcher-kva.example'));
    expect(value.unicodeValue, equals('bücher.example'));

    expect(() => KdlIdnHostname.convert(KdlString('not a hostname')),
        throwsA(anything));
  });
}
