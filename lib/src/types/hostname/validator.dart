import "./idna_converter.dart";

class HostnameValidator {
  static final partRgx = RegExp("^[a-z0-9_][a-z0-9_\\-]{0,62}\$", caseSensitive: false);

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

    return partRgx.hasMatch(part);
  }

  static validator() {

  }
}

class IDNHostnameValidator extends HostnameValidator {
  @override
  String unicode;

  IDNHostnameValidator.fromAscii(super.string) : unicode = IDNAConverter.urlDecode(string);
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
