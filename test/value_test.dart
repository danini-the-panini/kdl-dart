import 'package:test/test.dart';

import 'package:kdl/src/document.dart';

void main() {
  test('equals', () {
    expect(KdlInt(42), equals(KdlInt(42)));
    expect(KdlDouble(3.14), equals(KdlDouble(3.14)));
    expect(KdlDouble(double.nan), equals(KdlDouble(double.nan)));
    expect(KdlBool(true), equals(KdlBool(true)));
    expect(KdlNull, equals(KdlNull));
    expect(KdlString("lorem"), equals(KdlString("lorem")));

    expect(KdlInt(42), isNot(equals(KdlInt(69))));
    expect(KdlDouble(3.14), isNot(equals(KdlDouble(6.28))));
    expect(KdlBool(true), isNot(equals(KdlBool(false))));
    expect(KdlNull, isNot(equals(7)));
    expect(KdlString("lorem"), isNot(equals(KdlString("ipsum"))));
  });
}
