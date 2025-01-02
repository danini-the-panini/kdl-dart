import "./idna_converter.dart";

/// Validates hostnames
class HostnameValidator {
  static final _partRgx =
      RegExp("^[a-z0-9_][a-z0-9_\\-]{0,62}\$", caseSensitive: false);

  final String _string;

  /// ASCII Hostname value
  String get ascii => _string;

  /// Unicode hostname value
  String get unicode => _string;

  /// Construct a new `HostnameValidator` to validate the given string
  HostnameValidator(this._string);

  /// Return true if the string is a valid hostname
  bool isValid() {
    if (_string.length > 253) return false;

    return !_string.split('.').any((part) => !_validPart(part));
  }

  bool _validPart(String part) {
    if (part.isEmpty) return false;
    if (part.startsWith('-') || part.endsWith('-')) return false;

    return _partRgx.hasMatch(part);
  }
}

/// Hostname validator for Internationalized Domain Names
class IdnHostnameValidator extends HostnameValidator {
  @override
  String unicode;

  /// Validate an ASCII IDN Hostname
  IdnHostnameValidator.fromAscii(super.string)
      : unicode = IdnaConverter.urlDecode(string);

  /// Validate a Unicode IDN Hostname
  IdnHostnameValidator.fromUnicode(String string)
      : unicode = string,
        super(IdnaConverter.urlEncode(string));

  /// Constructs the appropriate IDN Hostname Validator depending on if the
  /// hostname is in ASCII or Unicode format
  factory IdnHostnameValidator(String string) {
    var isAscii = string.split('.').any((x) => x.startsWith('xn--'));
    if (isAscii) {
      return IdnHostnameValidator.fromAscii(string);
    } else {
      return IdnHostnameValidator.fromUnicode(string);
    }
  }
}
