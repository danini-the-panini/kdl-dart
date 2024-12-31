import "./hostname/validator.dart";

import "../document.dart";

/// RFC5322 email address.
class KdlEmail extends KdlValue<String> {
  /// Local email address part
  String local;

  /// Domain email address part
  String domain;

  /// Construct a new `KdlEmail`
  KdlEmail(super.value, this.local, this.domain, [super.type]);

  /// Convert a `KdlString` into a `KdlEmail`
  static KdlEmail? call(KdlValue value, [String type = 'email']) {
    if (value is! KdlString) return null;

    var parts = _EmailParser(value.value).parse();

    return KdlEmail(value.value, parts[0], parts[1], type);
  }
}

/// RFC6531 internationalized email address.
class KdlIDNEmail extends KdlEmail {
  /// Unicode value
  String unicodeValue;

  /// Unicode IDN
  String unicodeDomain;

  /// Construct a new `KdlIDNEmail`
  KdlIDNEmail(super.value, this.unicodeValue, super.local, super.domain,
      this.unicodeDomain,
      [super.type]);

  /// Convert a `KdlString` into a `KdlIDNEmail`
  static KdlIDNEmail? call(KdlValue value, [String type = 'idn-email']) {
    if (value is! KdlString) return null;

    var parts = _EmailParser(value.value, idn: true).parse();

    return KdlIDNEmail("${parts[0]}@${parts[1]}", "${parts[0]}@${parts[2]}",
        parts[0], parts[1], parts[2], type);
  }
}

enum _EmailParserContext {
  start,
  afterDot,
  afterPart,
  afterAt,
  afterDomain
}

class _EmailParser {
  final String _string;
  final bool _idn;
  final _EmailTokenizer _tokenizer;

  _EmailParser(this._string, {bool idn = false}) : _idn = idn,
    _tokenizer = _EmailTokenizer(_string, idn: idn);

  List<String> parse() {
    String local = '';
    late String unicodeDomain;
    late String domain;
    var context = _EmailParserContext.start;

    while (true) {
      var token = _tokenizer.nextToken();

      switch (token.type) {
        case _EmailTokenType.emailPart:
          switch (context) {
            case _EmailParserContext.start:
            case _EmailParserContext.afterDot:
              local += token.value;
              context = _EmailParserContext.afterPart;
              break;
            default:
              throw "invalid email $_string (unexpected part ${token.value} at $context)";
          }
          break;
        case _EmailTokenType.dot:
          switch (context) {
            case _EmailParserContext.afterPart:
              local += token.value;
              context = _EmailParserContext.afterDot;
              break;
            default:
              throw "invalid email $_string (unexpected dot at $context)";
          }
          break;
        case _EmailTokenType.at:
          switch (context) {
            case _EmailParserContext.afterPart:
              context = _EmailParserContext.afterAt;
              break;
            default:
              throw "invalid email $_string (unexpected dot at $context)";
          }
          break;
        case _EmailTokenType.domain:
          switch (context) {
            case _EmailParserContext.afterAt:
              var validator = _idn ? IDNHostnameValidator(token.value) : HostnameValidator(token.value);
              if (!validator.isValid()) throw "invalid hostname ${token.value}";

              unicodeDomain = validator.unicode;
              domain = validator.ascii;
              context = _EmailParserContext.afterDomain;
              break;
            default:
              throw "invalid email $_string (unexpected domain at $context)";
          }
          break;
        case _EmailTokenType.end:
          switch (context) {
            case _EmailParserContext.afterDomain:
              if (local.length > 64) {
                throw "invalid email $_string (local part length ${local.length} exceeds maximum of 64)";
              }

              return [local, domain, unicodeDomain];
            default:
              throw "invalid email $_string (unexpected end at $context)";
          }
      }
    }
  }
}

enum _EmailTokenType {
  emailPart,
  dot,
  at,
  domain,
  end,
}

class _EmailToken {
  _EmailTokenType type;
  String value;

  _EmailToken(this.type, this.value);

  @override
  String toString() => "$type:$value";
}

enum _EmailTokenizerContext {
  start,
  emailPart,
  quote,
}

class _EmailTokenizer {
  static final _localPartAscii = RegExp(r"[a-zA-Z0-9!#$%&'*+\-/=?^_`{|}~]");
  static final _localPartIdn = RegExp(r"""[^\x00-\x1f\s".@]""");

  final String _string;
  final bool _idn;
  int _index = 0;
  bool _afterAt = false;

  _EmailTokenizer(this._string, {bool idn = false}) : _idn = idn;

  String _substring(int start, [int? end]) {
    return String.fromCharCodes(_string.runes.toList().sublist(start, end ?? _length(_string)));
  }

  int _length(String str) {
    return str.runes.length;
  }

  _EmailToken nextToken() {
    if (_afterAt) {
      if (_index < _length(_string)) {
        var domainStart = _index;
        _index = _length(_string);
        return _EmailToken(_EmailTokenType.domain, _substring(domainStart));
      } else {
        return _EmailToken(_EmailTokenType.end, '');
      }
    }
    var context = _EmailTokenizerContext.start;
    var buffer = '';
    while (true) {
      if (_index >= _length(_string)) return _EmailToken(_EmailTokenType.end, '');
      var c = _charAt(_index);

      switch (context) {
      case _EmailTokenizerContext.start:
        switch (c) {
        case '.':
          _index++;
          return _EmailToken(_EmailTokenType.dot, '.');
        case '@':
          _afterAt = true;
          _index++;
          return _EmailToken(_EmailTokenType.at, '@');
        case '"':
          context = _EmailTokenizerContext.quote;
          _index++;
          break;
        default:
          if (_localPartChars().hasMatch(c)) {
            context = _EmailTokenizerContext.emailPart;
            buffer += c;
            _index++;
            break;
          }
          throw "invalid email $_string, (unexpected $c)";
        }
        break;
      case _EmailTokenizerContext.emailPart:
        if (_localPartChars().hasMatch(c)) {
          buffer += c;
          _index++;
        } else if (c == '.' || c == '@') {
          return _EmailToken(_EmailTokenType.emailPart, buffer);
        } else {
          throw "invalid email $_string (unexpected $c)";
        }
        break;
      case _EmailTokenizerContext.quote:
        if (c == '"') {
          var n = _charAt(_index + 1);
          if (n != '.' && n != '@') {
            throw "invalid email $_string (unexpected $c)";
          }

          _index++;
          return _EmailToken(_EmailTokenType.emailPart, buffer);
        } else {
          buffer += c;
          _index += 1;
        }
        break;
      }
    }
  }

  RegExp _localPartChars() => _idn ? _localPartIdn : _localPartAscii;

  String _charAt(int i) => String.fromCharCode(_string.runes.elementAt(i));
}
