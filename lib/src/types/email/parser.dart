import "../hostname/validator.dart";

enum EmailParserContext {
  Start,
  AfterDot,
  AfterPart,
  AfterAt,
  AfterDomain
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
    var context = EmailParserContext.Start;
    
    while (true) {
      var token = tokenizer.nextToken();

      switch (token.type) {
        case EmailTokenType.Part:
          switch (context) {
            case EmailParserContext.Start:
            case EmailParserContext.AfterDot:
              local += token.value;
              context = EmailParserContext.AfterPart;
              break;
            default:
              throw "invalid email $string (unexpected part ${token.value} at $context)";
          }
          break;
        case EmailTokenType.Dot:
          switch (context) {
            case EmailParserContext.AfterPart:
              local += token.value;
              context = EmailParserContext.AfterDot;
              break;
            default:
              throw "invalid email $string (unexpected dot at $context)";
          }
          break;
        case EmailTokenType.At:
          switch (context) {
            case EmailParserContext.AfterPart:
              context = EmailParserContext.AfterAt;
              break;
            default:
              throw "invalid email $string (unexpected dot at $context)";
          }
          break;
        case EmailTokenType.Domain:
          switch (context) {
            case EmailParserContext.AfterAt:
              var validator = idn ? IDNHostnameValidator(token.value) : HostnameValidator(token.value);
              if (!validator.isValid()) throw "invalid hostname ${token.value}";

              unicodeDomain = validator.unicode;
              domain = validator.ascii;
              context = EmailParserContext.AfterDomain;
              break;
            default:
              throw "invalid email $string (unexpected domain at $context)";
          }
          break;
        case EmailTokenType.End:
          switch (context) {
            case EmailParserContext.AfterDomain:
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
  Part,
  Dot,
  At,
  Domain,
  End,
}

class EmailToken {
  EmailTokenType type;
  String value;

  EmailToken(this.type, this.value);

  @override
  String toString() => "$type:$value";
}

enum EmailTokenizerContext {
  Start,
  Part,
  Quote,
}

class EmailTokenizer {
  static final LOCAL_PART_ASCII = RegExp(r"[a-zA-Z0-9!#$%&'*+\-/=?^_`{|}~]");
  static final LOCAL_PART_IDN = RegExp(r"""[^\x00-\x1f\s".@]""");

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
        return EmailToken(EmailTokenType.Domain, _substring(domainStart));
      } else {
        return EmailToken(EmailTokenType.End, '');
      }
    }
    var context = EmailTokenizerContext.Start;
    var buffer = '';
    while (true) {
      if (index >= _length(string)) return EmailToken(EmailTokenType.End, '');
      var c = _charAt(index);

      switch (context) {
      case EmailTokenizerContext.Start:
        switch (c) {
        case '.':
          index++;
          return EmailToken(EmailTokenType.Dot, '.');
        case '@':
          afterAt = true;
          index++;
          return EmailToken(EmailTokenType.At, '@');
        case '"':
          context = EmailTokenizerContext.Quote;
          index++;
          break;
        default:
          if (_localPartChars().hasMatch(c)) {
            context = EmailTokenizerContext.Part;
            buffer += c;
            index++;
            break;
          }
          throw "invalid email $string, (unexpected $c)";
        }
        break;
      case EmailTokenizerContext.Part:
        if (_localPartChars().hasMatch(c)) {
          buffer += c;
          index++;
        } else if (c == '.' || c == '@') {
          return EmailToken(EmailTokenType.Part, buffer);
        } else {
          throw "invalid email $string (unexpected $c)";
        }
        break;
      case EmailTokenizerContext.Quote:
        if (c == '"') {
          var n = _charAt(index + 1);
          if (n != '.' && n != '@') {
            throw "invalid email $string (unexpected $c)";
          }

          index++;
          return EmailToken(EmailTokenType.Part, buffer);
        } else {
          buffer += c;
          index += 1;
        }
        break;
      }
    }
  }

  RegExp _localPartChars() => idn ? LOCAL_PART_IDN : LOCAL_PART_ASCII;

  String _charAt(int i) => String.fromCharCode(string.runes.elementAt(i));
}
