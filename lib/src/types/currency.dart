import "../document.dart";
import "./currency/iso4217_currencies.dart";

/// ISO 4217 currency code.
class KdlCurrency extends KdlValue<Currency> {
  /// Construct a new `KdlCurrency`
  KdlCurrency(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlCurrency`
  static KdlCurrency? call(KdlValue value, [String type = 'currency']) {
    if (value is! KdlString) return null;

    var currency = Currency.currencies[value.value];
    if (currency == null) throw "invalid currency: ${value.value}";

    return KdlCurrency(currency, type);
  }
}
