import "./IDNAConverter.dart";

class HostnameValidator {
  static final PART_RGX = RegExp("^[a-z0-9_][a-z0-9_\\-]{0,62}\$", caseSensitive: false);

  String string;
  String get ascii => string;
  String get unicode => string;

  HostnameValidator(this.string);

  bool isValid() {
    if (string.length > 253) return false;

    return !string.split('.').any((part) => !_validPart(part));
  }

  bool _validPart(String part) {
    if (part.isEmpty) return false;
    if (part.startsWith('-') || part.endsWith('-')) return false;

    return PART_RGX.hasMatch(part);
  }

  static validator() {

  }
}

class IDNHostnameValidator extends HostnameValidator {
  String unicode;

  IDNHostnameValidator.fromAscii(String string) : unicode = IDNAConverter.urlDecode(string), super(string);
  IDNHostnameValidator.fromUnicode(String string) : unicode = string, super(IDNAConverter.urlEncode(string));

  factory IDNHostnameValidator(String string) {
    var isAscii = string.split('.').any((x) => x.startsWith('xn--'));
    if (isAscii) {
      return IDNHostnameValidator.fromAscii(string);
    } else {
      return IDNHostnameValidator.fromUnicode(string);
    }
  }
}
