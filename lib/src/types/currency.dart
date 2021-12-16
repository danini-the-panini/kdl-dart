import "../document.dart";
import "./currency/iso4217_currencies.dart";

class KdlCurrency extends KdlValue<Currency> {
  KdlCurrency(Currency value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'currency']) {
    if (!(value is KdlString)) return null;
    
    var currency = Currency.CURRENCIES[value.value];
    if (currency == null) throw "invalid currency: ${value.value}";

    return KdlCurrency(currency, type);
  }
}
