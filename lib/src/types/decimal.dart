import 'package:big_decimal/big_decimal.dart';

import "../document.dart";

class KdlDecimal extends KdlValue<BigDecimal> {
  KdlDecimal(BigDecimal value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'decimal']) {
    if (!(value is KdlString)) return null;

    return KdlDecimal(BigDecimal.parse(value.value), type);
  }
}
