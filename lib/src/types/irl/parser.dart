import "dart:convert";

import "../hostname/validator.dart";

class IRLReferenceParser {
  static final RGX = RegExp(r"^(?:(?:([a-z][a-z0-9+.\-]+)):\/\/([^@]+@)?([^\/?#]+)?)?(\/?[^?#]*)?(?:\?([^#]*))?(?:#(.*))?$", caseSensitive: false);
  static final PERCENT_RGX = RegExp(r"%([a-f0-9]{2})", caseSensitive: false);

  static const RESERVED_URL_CHARS = [
    '!', '#', '&', "'", '(', ')', '*', '+', ',', '/', ':', ';', '=', '?', '@', '[', ']', '%'
  ];
  static const UNRESERVED_URL_CHARS = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '_', '.', '~'
  ];
  static final URL_CHARS = RESERVED_URL_CHARS + UNRESERVED_URL_CHARS;

  String string;
  
  IRLReferenceParser(this.string);

  parse() {
    List<String?> parts = _parseUrl();
    var scheme = parts[0];
    var auth = parts[1];
    var domain = parts[2];
    var path = parts[3];
    var search = parts[4];
    var hash = parts[5];

    String? unicodeDomain = null;
    String? unicodePath = null;
    String? unicodeSearch = null;
    String? unicodeHash = null;

    if (string.runes.any((rune) => rune > 127)) {
      unicodePath = path;
      path = _encode(unicodePath);
      unicodeSearch = search;
      var searchParams = unicodeSearch == null ? null : unicodeSearch.split('&').map((x) => x.split('='));
      search = searchParams == null ? null : searchParams.map((x) => "${_encode(x[0])}=${_encode(x[1])}").join('&');
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

    var unicodeValue = _buildUriString(scheme, auth, unicodeDomain, unicodePath, unicodeSearch, unicodeHash);
    var asciiValue = _buildUriString(scheme, auth, domain, path, search, hash);

    return [
      asciiValue,
      unicodeValue,
      unicodeDomain,
      unicodePath,
      unicodeSearch,
      unicodeHash
    ];
  }

  List<String?> _parseUrl() {
    var match = RGX.firstMatch(string);
    if (match == null) throw "invalid IRL $string";

    var parts = match.groups([1,2,3,4,5,6]);
    if (parts.any((part) => !_isValidUrlPart(part))) throw "invalid IRL $string";

    return parts;
  }

  static _isValidUrlPart(String? string) {
    if (string == null) return true;

    return !string.runes.any((rune) =>
      rune <= 127 && !URL_CHARS.contains(String.fromCharCode(rune)));
  }

  static _encode(String? string) {
    if (string == null) return null;

    return string.runes
      .map((c) => c <= 127 ? String.fromCharCode(c) : percentEncode(String.fromCharCode(c)))
      .join();
  }

  static _decode(String? string) {
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

  static percentEncode(String c) {
    return utf8.encode(c).map((b) => "%${b.toRadixString(16)}").join().toUpperCase();
  }

  static _buildUriString(String? scheme, String? auth, String? domain, String? path, String? search, String? hash) {
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

class IRLParser extends IRLReferenceParser {
  IRLParser(String string): super(string);

  @override
  _parseUrl() {
    var parts = super._parseUrl();
    var scheme = parts[0];
    if (scheme == null || scheme.isEmpty) throw "invalid IRL $string";

    return parts;
  }
}
