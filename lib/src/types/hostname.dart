import "../document.dart";
import "./hostname/validator.dart";

/// RFC1132 internet hostname (only ASCII segments)
class KdlHostname extends KdlValue<String> {
  /// Construct a new `KdlHostname`
  KdlHostname(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlHostname`
  static KdlHostname? convert(KdlValue value, [String type = 'hostname']) {
    if (value is! KdlString) return null;
    var validator = HostnameValidator(value.value);
    if (!validator.isValid()) throw "invalid hostname ${value.value}";

    return KdlHostname(value.value, type);
  }
}

/// RFC5890 internationalized internet hostname
/// (only `xn--`-prefixed ASCII "punycode" segments, or non-ASCII segments)
class KdlIdnHostname extends KdlHostname {
  /// Unicode value
  String unicodeValue;

  /// Construct a new `KdlIDNHostname`
  KdlIdnHostname(String value, this.unicodeValue, [String? type])
      : super(value, type);

  /// Convert a `KdlString` into a `KdlIDNHostname`
  static KdlIdnHostname? convert(KdlValue value,
      [String type = 'idn-hostname']) {
    if (value is! KdlString) return null;
    var validator = IdnHostnameValidator(value.value);
    if (!validator.isValid()) throw "invalid hostname ${value.value}";

    return KdlIdnHostname(validator.ascii, validator.unicode, type);
  }
}
