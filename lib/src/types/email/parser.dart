import "../hostname/validator.dart";

enum EmailParserContext {
  start,
  afterDot,
  afterPart,
  afterAt,
  afterDomain
}

class EmailParser {
  String string;
  bool idn;
  EmailTokenizer tokenizer;

  EmailParser(this.string, {this.idn = false}) :
    tokenizer = EmailTokenizer(string, idn: idn);

  List<String> parse() {
    String local = '';
    late String unicodeDomain;
    late String domain;
    var context = EmailParserContext.start;

    while (true) {
      var token = tokenizer.nextToken();

      switch (token.type) {
        case EmailTokenType.emailPart:
          switch (context) {
            case EmailParserContext.start:
            case EmailParserContext.afterDot:
              local += token.value;
              context = EmailParserContext.afterPart;
              break;
            default:
              throw "invalid email $string (unexpected part ${token.value} at $context)";
          }
          break;
        case EmailTokenType.dot:
          switch (context) {
            case EmailParserContext.afterPart:
              local += token.value;
              context = EmailParserContext.afterDot;
              break;
            default:
              throw "invalid email $string (unexpected dot at $context)";
          }
          break;
        case EmailTokenType.at:
          switch (context) {
            case EmailParserContext.afterPart:
              context = EmailParserContext.afterAt;
              break;
            default:
              throw "invalid email $string (unexpected dot at $context)";
          }
          break;
        case EmailTokenType.domain:
          switch (context) {
            case EmailParserContext.afterAt:
              var validator = idn ? IDNHostnameValidator(token.value) : HostnameValidator(token.value);
              if (!validator.isValid()) throw "invalid hostname ${token.value}";

              unicodeDomain = validator.unicode;
              domain = validator.ascii;
              context = EmailParserContext.afterDomain;
              break;
            default:
              throw "invalid email $string (unexpected domain at $context)";
          }
          break;
        case EmailTokenType.end:
          switch (context) {
            case EmailParserContext.afterDomain:
              if (local.length > 64) {
                throw "invalid email $string (local part length ${local.length} exceeds maximum of 64)";
              }

              return [local, domain, unicodeDomain];
            default:
              throw "invalid email $string (unexpected end at $context)";
          }
      }
    }
  }
}

enum EmailTokenType {
  emailPart,
  dot,
  at,
  domain,
  end,
}

class EmailToken {
  EmailTokenType type;
  String value;

  EmailToken(this.type, this.value);

  @override
  String toString() => "$type:$value";
}

enum EmailTokenizerContext {
  start,
  emailPart,
  quote,
}

class EmailTokenizer {
  static final localPartAscii = RegExp(r"[a-zA-Z0-9!#$%&'*+\-/=?^_`{|}~]");
  static final localPartIdn = RegExp(r"""[^\x00-\x1f\s".@]""");

  String string;
  bool idn;
  int index = 0;
  bool afterAt = false;

  EmailTokenizer(this.string, {this.idn = false});

  String _substring(int start, [int? end]) {
    return String.fromCharCodes(string.runes.toList().sublist(start, end ?? _length(string)));
  }

  int _length(String str) {
    return str.runes.length;
  }

  EmailToken nextToken() {
    if (afterAt) {
      if (index < _length(string)) {
        var domainStart = index;
        index = _length(string);
        return EmailToken(EmailTokenType.domain, _substring(domainStart));
      } else {
        return EmailToken(EmailTokenType.end, '');
      }
    }
    var context = EmailTokenizerContext.start;
    var buffer = '';
    while (true) {
      if (index >= _length(string)) return EmailToken(EmailTokenType.end, '');
      var c = _charAt(index);

      switch (context) {
      case EmailTokenizerContext.start:
        switch (c) {
        case '.':
          index++;
          return EmailToken(EmailTokenType.dot, '.');
        case '@':
          afterAt = true;
          index++;
          return EmailToken(EmailTokenType.at, '@');
        case '"':
          context = EmailTokenizerContext.quote;
          index++;
          break;
        default:
          if (_localPartChars().hasMatch(c)) {
            context = EmailTokenizerContext.emailPart;
            buffer += c;
            index++;
            break;
          }
          throw "invalid email $string, (unexpected $c)";
        }
        break;
      case EmailTokenizerContext.emailPart:
        if (_localPartChars().hasMatch(c)) {
          buffer += c;
          index++;
        } else if (c == '.' || c == '@') {
          return EmailToken(EmailTokenType.emailPart, buffer);
        } else {
          throw "invalid email $string (unexpected $c)";
        }
        break;
      case EmailTokenizerContext.quote:
        if (c == '"') {
          var n = _charAt(index + 1);
          if (n != '.' && n != '@') {
            throw "invalid email $string (unexpected $c)";
          }

          index++;
          return EmailToken(EmailTokenType.emailPart, buffer);
        } else {
          buffer += c;
          index += 1;
        }
        break;
      }
    }
  }

  RegExp _localPartChars() => idn ? localPartIdn : localPartAscii;

  String _charAt(int i) => String.fromCharCode(string.runes.elementAt(i));
}
