import 'package:big_decimal/big_decimal.dart';

import "../document.dart";

/// IEEE 754-2008 decimal string format.
class KdlDecimal extends KdlValue<BigDecimal> {
  /// Construct a new `KdlDecimal`
  KdlDecimal(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlDecimal`
  static KdlDecimal? convert(KdlValue value, [String type = 'decimal']) {
    if (value is! KdlString) return null;

    return KdlDecimal(BigDecimal.parse(value.value), type);
  }
}
