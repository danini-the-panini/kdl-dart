import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/currency.dart';
import 'package:kdl/src/types/currency/iso4217_currencies.dart';

void main() {
  test('uuid', () {
    expect(KdlCurrency.convert(KdlString('ZAR'))!.value,
      equals(Currency(numericCode: 710, minorUnit: 2, name: 'South African rand')));

    expect(() => KdlCurrency.convert(KdlString('ZZZ')), throwsA(anything));
  });
}
