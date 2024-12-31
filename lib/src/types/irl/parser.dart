import "dart:convert";

import "../hostname/validator.dart";

/// RFC3987 Internationalized Resource Identifier.
class IRL {
  /// ASCII punycode value
  String asciiValue;

  /// Unicode value
  String unicodeValue;

  /// Unicode domain
  String? unicodeDomain;

  /// Unicode path
  String? unicodePath;

  /// Unicode search query
  String? unicodeSearch;

  /// Unicode hash value
  String? unicodeHash;

  /// Construct a new IRL
  IRL(this.asciiValue, this.unicodeValue,
      [this.unicodeDomain,
      this.unicodePath,
      this.unicodeSearch,
      this.unicodeHash]);
}

/// Parses a string into an IRL
class IRLParser {
  static final _rgx = RegExp(
      r"^(?:(?:([a-z][a-z0-9+.\-]+)):\/\/([^@]+@)?([^\/?#]+)?)?(\/?[^?#]*)?(?:\?([^#]*))?(?:#(.*))?$",
      caseSensitive: false);

  static const _reservedUrlChars = [
    '!',
    '#',
    '&',
    "'",
    '(',
    ')',
    '*',
    '+',
    ',',
    '/',
    ':',
    ';',
    '=',
    '?',
    '@',
    '[',
    ']',
    '%'
  ];
  static const _unreservedUrlChars = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '-',
    '_',
    '.',
    '~'
  ];
  static final _urlChars = _reservedUrlChars + _unreservedUrlChars;

  final String _string;
  final bool _isReference;

  /// Construct a new parser to parse the given string
  /// pass `isReference: false` to validate this as a full IRL
  /// (i.e. has a scheme)
  IRLParser(this._string, {isReference = true}) : _isReference = isReference;

  /// Parse the string into an IRL
  IRL parse() {
    List<String?> parts = _parseUrl();
    var scheme = parts[0];
    if (!_isReference && (scheme == null || scheme.isEmpty)) {
      throw "invalid IRL $_string";
    }
    var auth = parts[1];
    var domain = parts[2];
    var path = parts[3];
    var search = parts[4];
    var hash = parts[5];

    String? unicodeDomain;
    String? unicodePath;
    String? unicodeSearch;
    String? unicodeHash;

    if (_string.runes.any((rune) => rune > 127)) {
      unicodePath = path;
      path = _encode(unicodePath);
      unicodeSearch = search;
      var searchParams = unicodeSearch?.split('&').map((x) => x.split('='));
      search = searchParams
          ?.map((x) => "${_encode(x[0])}=${_encode(x[1])}")
          .join('&');
      unicodeHash = hash;
      hash = _encode(hash);
    } else {
      unicodePath = _decode(path);
      unicodeSearch = _decode(search);
      unicodeHash = _decode(hash);
    }

    if (domain != null) {
      var validator = IDNHostnameValidator(domain);
      domain = validator.ascii;
      unicodeDomain = validator.unicode;
    } else {
      unicodeDomain = domain;
    }

    var unicodeValue = _buildUriString(
        scheme, auth, unicodeDomain, unicodePath, unicodeSearch, unicodeHash);
    var asciiValue = _buildUriString(scheme, auth, domain, path, search, hash);

    return IRL(asciiValue, unicodeValue, unicodeDomain, unicodePath,
        unicodeSearch, unicodeHash);
  }

  List<String?> _parseUrl() {
    var match = _rgx.firstMatch(_string);
    if (match == null) throw "invalid IRL $_string";

    var parts = match.groups([1, 2, 3, 4, 5, 6]);
    if (parts.any((part) => !_isValidUrlPart(part))) {
      throw "invalid IRL $_string";
    }

    return parts;
  }

  static bool _isValidUrlPart(String? string) {
    if (string == null) return true;

    return !string.runes.any((rune) =>
        rune <= 127 && !_urlChars.contains(String.fromCharCode(rune)));
  }

  static String? _encode(String? string) {
    if (string == null) return null;

    return string.runes
        .map((c) => c <= 127
            ? String.fromCharCode(c)
            : percentEncode(String.fromCharCode(c)))
        .join();
  }

  static String? _decode(String? string) {
    if (string == null) return null;

    List<int> bytes = [];
    for (int i = 0; i < string.length; i++) {
      var c = string[i];
      if (c == '%' && i < string.length - 2) {
        bytes.add(int.parse(string.substring(i + 1, i + 3), radix: 16));
        i += 2;
      } else {
        bytes.addAll(utf8.encode(c));
      }
    }

    return utf8.decode(bytes);
  }

  /// URL-encode the given string
  static String percentEncode(String c) {
    return utf8
        .encode(c)
        .map((b) => "%${b.toRadixString(16)}")
        .join()
        .toUpperCase();
  }

  static String _buildUriString(String? scheme, String? auth, String? domain,
      String? path, String? search, String? hash) {
    var string = '';
    if (scheme != null) string += "$scheme://";
    if (auth != null) string += auth;
    if (domain != null) string += domain;
    if (path != null) string += path;
    if (search != null) string += "?$search";
    if (hash != null) string += "#$hash";
    return string;
  }
}
