import "../document.dart";
import "./hostname/validator.dart";

class KdlHostname extends KdlValue<String> {
  KdlHostname(String value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'hostname']) {
    if (!(value is KdlString)) return null;
    var validator = HostnameValidator(value.value);
    if (!validator.isValid()) throw "invalid hostname ${value.value}";

    return KdlHostname(value.value, type);
  }
}

class KdlIDNHostname extends KdlHostname {
  String unicodeValue;

  KdlIDNHostname(String value, this.unicodeValue, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'idn-hostname']) {
    if (!(value is KdlString)) return null;
    var validator = IDNHostnameValidator(value.value);
    if (!validator.isValid()) throw "invalid hostname ${value.value}";

    return KdlIDNHostname(validator.ascii, validator.unicode, type);
  }
}
