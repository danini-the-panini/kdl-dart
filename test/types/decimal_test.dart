import 'package:test/test.dart';
import 'package:big_decimal/big_decimal.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/decimal.dart';

void main() {
  test('decimal', () {
    expect(KdlDecimal.call(KdlString('10000000000000'))!.value,
      equals(BigDecimal.parse('10000000000000')));

    expect(() => KdlDecimal.call(KdlString('not a decimal')), throwsA(anything));
  });
}
