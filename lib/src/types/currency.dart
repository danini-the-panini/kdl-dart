import "../document.dart";
import "./currency/iso4217_currencies.dart";

class KdlCurrency extends KdlValue<Currency> {
  KdlCurrency(super.value, [super.type]);

  static call(KdlValue value, [String type = 'currency']) {
    if (value is! KdlString) return null;

    var currency = Currency.currencies[value.value];
    if (currency == null) throw "invalid currency: ${value.value}";

    return KdlCurrency(currency, type);
  }
}
