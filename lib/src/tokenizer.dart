import 'dart:collection';
import 'package:big_decimal/big_decimal.dart';

enum KdlTokenizerContext {
  ident,
  keyword,
  string,
  rawstring,
  multiLineString,
  multiLineRawstring,
  binary,
  octal,
  hexadecimal,
  decimal,
  singleLineComment,
  multiLineComment,
  whitespace,
  equals,
}

enum KdlToken {
  IDENT,
  STRING,
  RAWSTRING,
  INTEGER,
  DECIMAL,
  DOUBLE,
  TRUE,
  FALSE,
  NULL,
  WS,
  NEWLINE,
  LBRACE,
  RBRACE,
  LPAREN,
  RPAREN,
  EQUALS,
  SEMICOLON,
  EOF,
  SLASHDASH,
}

List charRange(int from, int to) =>
    List.generate(to - from + 1, (i) => String.fromCharCode(i + from));

String debom(String str) {
  if (str.startsWith("\uFEFF")) {
    return str.substring(1);
  }

  return str;
}

class KdlTokenizer {
  static final SYMBOLS = {
    '{': KdlToken.LBRACE,
    '}': KdlToken.RBRACE,
    ';': KdlToken.SEMICOLON,
    '=': KdlToken.EQUALS
  };

  static const WHITESPACE = [
    "\u0009",
    "\u0020",
    "\u00A0",
    "\u1680",
    "\u2000",
    "\u2001",
    "\u2002",
    "\u2003",
    "\u2004",
    "\u2005",
    "\u2006",
    "\u2007",
    "\u2008",
    "\u2009",
    "\u200A",
    "\u202F",
    "\u205F",
    "\u3000"
  ];
  static final WS = "[${RegExp.escape(WHITESPACE.join())}]";
  static final WS_STAR = RegExp("^${WS}*\$");
  static final WS_PLUS = RegExp("^${WS}+\$");

  static const NEWLINES = ["\u000A", "\u0085", "\u000B", "\u000C", "\u2028", "\u2029"];
  static final NEWLINES_PATTERN =
      RegExp.new("${NEWLINES.map(RegExp.escape).join('|')}|\\r\\n?");

  static final NON_IDENTIFIER_CHARS = [
    null,
    ...WHITESPACE,
    ...NEWLINES,
    ...SYMBOLS.keys,
    "\r",
    "\\",
    "[",
    "]",
    "(",
    ")",
    '"',
    "/",
    "#",
    ...charRange(0x0000, 0x0020),
  ];
  static final NON_INITIAL_IDENTIFIER_CHARS = [
    ...NON_IDENTIFIER_CHARS,
    ...List.generate(10, (index) => index.toString()),
  ];

  static final FORBIDDEN = [
    ...charRange(0x0000, 0x0008),
    ...charRange(0x000E, 0x001F),
    "\u007F",
    ...charRange(0x200E, 0x200F),
    ...charRange(0x202A, 0x202E),
    ...charRange(0x2066, 0x2069),
    "\uFEFF"
  ];

  String str = '';
  KdlTokenizerContext? context = null;
  int rawstringHashes = -1;
  int index = 0;
  int start = 0;
  String buffer = "";
  bool done = false;
  KdlTokenizerContext? previousContext = null;
  int commentNesting = 0;
  Queue peekedTokens = Queue();
  bool inType = false;
  KdlToken? lastToken = null;

  KdlTokenizer(String str, {int this.start = 0}) {
    // print("--- TOKENIZING ---");
    this.str = debom(str);
    this.index = start;
  }

  static final VERSION_PATTERN = RegExp(
      "\\/-${WS}*kdl-version${WS}+(\\d+)${WS}*${NEWLINES_PATTERN.pattern}");

  versionDirective() {
    var match = VERSION_PATTERN.matchAsPrefix(str);
    if (match == null) return null;
    var m = match.group(1);
    if (m == null) return null;
    return int.parse(m);
  }

  reset() {
    index = start;
  }

  allTokens() {
    List a = [];
    while (!done) {
      a.add(nextToken());
    }
    return a;
  }

  _setContext(KdlTokenizerContext? ctx) {
    // print('ctx: $context -> $ctx');
    previousContext = context;
    context = ctx;
  }

  peekToken() {
    if (peekedTokens.isEmpty) {
      peekedTokens.add(_nextToken());
    }
    return peekedTokens.first;
  }

  peekTokenAfterNext() {
    if (peekedTokens.isEmpty) {
      peekedTokens.add(_nextToken());
      peekedTokens.add(_nextToken());
    } else if (peekedTokens.length == 1) {
      peekedTokens.add(_nextToken());
    }
    return peekedTokens.elementAt(1);
  }

  nextToken() {
    if (peekedTokens.isNotEmpty) {
      return peekedTokens.removeFirst();
    } else {
      return _nextToken();
    }
  }

  _nextToken() {
    var token = _readNextToken();
    if (token[0] != false) lastToken = token[0];
    // print("TOKEN: ${token[0]}, '${token[1].toString()}'");
    return token;
  }

  _readNextToken() {
    context = null;
    previousContext = null;
    // print('reading token...');
    while (true) {
      var c = _charAt(index);
      // print("@ $index: '$c'");
      if (context == null) {
        if (c == null) {
          if (done) {
            return [false, false];
          }
          done = true;
          return [KdlToken.EOF, ''];
        } else if (c == '"') {
          if (_charAt(index + 1) == '"' && _charAt(index + 2) == '"') {
            String nl = _expectNewline(index + 3);
            _setContext(KdlTokenizerContext.multiLineString);
            buffer = '';
            index += 3 + nl.runes.length;
          } else {
            _setContext(KdlTokenizerContext.string);
            buffer = '';
            index += 1;
          }
        } else if (c == '#') {
          if (_charAt(index + 1) == '"') {
            if (_charAt(index + 2) == '"' && _charAt(index + 3) == '"') {
              String nl = _expectNewline(index + 4);
              _setContext(KdlTokenizerContext.multiLineRawstring);
              rawstringHashes = 1;
              buffer = '';
              index += 4 + nl.runes.length;
              continue;
            } else {
              _setContext(KdlTokenizerContext.rawstring);
              index += 2;
              rawstringHashes = 1;
              buffer = '';
              continue;
            }
          } else if (_charAt(index + 1) == '#') {
            var i = index + 1;
            rawstringHashes = 1;
            while (_charAt(i) == '#') {
              rawstringHashes += 1;
              i += 1;
            }
            if (_charAt(i) == '"') {
              if (_charAt(i + 1) == '"' && _charAt(i + 2) == '"') {
                String nl = _expectNewline(i + 3);
                _setContext(KdlTokenizerContext.multiLineRawstring);
                buffer = '';
                index += rawstringHashes + 3 + nl.runes.length;
                continue;
              } else {
                _setContext(KdlTokenizerContext.rawstring);
                index += rawstringHashes + 1;
                buffer = '';
                continue;
              }
            }
          }
          _setContext(KdlTokenizerContext.keyword);
          buffer = c;
          index += 1;
        } else if (c == '-') {
          var n = _charAt(index + 1);
          var n2 = _charAt(index + 2);
          if (n != null && RegExp(r"[0-9]").hasMatch(n)) {
            if (n == '0' && n2 != null && RegExp(r"[box]").hasMatch(n2)) {
              _setContext(_integerContext(n2));
              index += 2;
            } else {
              _setContext(KdlTokenizerContext.decimal);
            }
          } else {
            _setContext(KdlTokenizerContext.ident);
          }
          buffer = c;
          index += 1;
        } else if (RegExp(r"[0-9+]").hasMatch(c)) {
          var n = _charAt(index + 1);
          var n2 = _charAt(index + 2);
          if (c == '0' && n != null && RegExp("[box]").hasMatch(n)) {
            index += 2;
            buffer = '';
            _setContext(_integerContext(n));
          } else if (c == '+' && n == '0' && RegExp("[box]").hasMatch(n2)) {
            index += 3;
            buffer = c;
            _setContext(_integerContext(n2));
          } else {
            _setContext(KdlTokenizerContext.decimal);
            index += 1;
            buffer = c;
          }
        } else if (c == "\\") {
          var t = KdlTokenizer(str, start: index + 1);
          var la = t.nextToken();
          if (la[0] == KdlToken.NEWLINE || la[0] == KdlToken.EOF) {
            index = t.index;
            _setContext(KdlTokenizerContext.whitespace);
            buffer = "${c}${la[1]}";
            continue;
          } else if (la[0] == KdlToken.WS) {
            var lan = t.nextToken();
            if (lan[0] == KdlToken.NEWLINE || lan[0] == KdlToken.EOF) {
              index = t.index;
              _setContext(KdlTokenizerContext.whitespace);
              buffer = "${c}${la[1]}";
              if (lan[0] == KdlToken.NEWLINE) {
                buffer += "\n";
              }
              continue;
            }
          }
          throw "Unexpected '\\'";
        } else if (c == '=') {
          _setContext(KdlTokenizerContext.equals);
          buffer = c;
          index += 1;
        } else if (SYMBOLS.containsKey(c)) {
          index += 1;
          return [SYMBOLS[c], c];
        } else if (c == "\r" || NEWLINES.contains(c)) {
          String nl = _expectNewline(index);
          index += nl.runes.length;
          return [KdlToken.NEWLINE, nl];
        } else if (c == "/") {
          var n = _charAt(index + 1);
          if (n == '/') {
            if (inType || lastToken == KdlToken.RPAREN) throw "Unexpected '/'";
            _setContext(KdlTokenizerContext.singleLineComment);
            index += 2;
          } else if (n == '*') {
            _setContext(KdlTokenizerContext.multiLineComment);
            commentNesting = 1;
            index += 2;
          } else if (n == '-') {
            index += 2;
            return [KdlToken.SLASHDASH, '/-'];
          } else {
            throw "Unexpected character '${c}'";
          }
        } else if (WHITESPACE.contains(c)) {
          _setContext(KdlTokenizerContext.whitespace);
          buffer = c;
          index += 1;
        } else if (!NON_INITIAL_IDENTIFIER_CHARS.contains(c)) {
          _setContext(KdlTokenizerContext.ident);
          buffer = c;
          index += 1;
        } else if (c == '(') {
          inType = true;
          index += 1;
          return [KdlToken.LPAREN, c];
        } else if (c == ')') {
          inType = false;
          index += 1;
          return [KdlToken.RPAREN, c];
        } else {
          throw "Unexpected character '${c}'";
        }
      } else {
        switch (context) {
          case KdlTokenizerContext.ident:
            if (!NON_IDENTIFIER_CHARS.contains(c)) {
              index += 1;
              buffer += c;
              break;
            } else {
              if (['true', 'false', 'null', 'inf', '-inf', 'nan']
                  .contains(buffer)) {
                throw "Identifier cannot be a literal";
              } else if (RegExp(r"^\.\d").hasMatch(buffer)) {
                throw "Identifier cannot look like an illegal float";
              } else {
                return [KdlToken.IDENT, buffer];
              }
            }
          case KdlTokenizerContext.keyword:
            if (c != null && RegExp(r"[a-z\-]").hasMatch(c)) {
              index += 1;
              buffer += c;
              break;
            } else {
              switch (buffer) {
                case '#true':
                  return [KdlToken.TRUE, true];
                case '#false':
                  return [KdlToken.FALSE, false];
                case '#null':
                  return [KdlToken.NULL, null];
                case '#inf':
                  return [KdlToken.DOUBLE, double.infinity];
                case '#-inf':
                  return [KdlToken.DOUBLE, -double.infinity];
                case '#nan':
                  return [KdlToken.DOUBLE, double.nan];
                default:
                  throw "Unknown keyword ${buffer}";
              }
            }
          case KdlTokenizerContext.string:
            switch (c) {
              case '\\':
                buffer += c;
                var c2 = _charAt(index + 1);
                buffer += c2;
                if (NEWLINES.contains(c2)) {
                  var i = 2;
                  while (NEWLINES.contains(c2 = _charAt(index + i))) {
                    buffer += c2;
                    i += 1;
                  }
                  index += i;
                } else {
                  index += 2;
                }
                break;
              case '"':
                index += 1;
                return [KdlToken.STRING, _unescape(buffer)];
              case '':
              case null:
                throw "Unterminated string literal";
              default:
                if (NEWLINES.contains(c)) {
                  throw "Unexpected NEWLINE in single-line string";
                }
                buffer += c;
                index += 1;
                break;
            }
            break;
          case KdlTokenizerContext.multiLineString:
            switch (c) {
              case '\\':
                buffer += c;
                buffer += _charAt(index + 1);
                index += 2;
                break;
              case '"':
                if (_charAt(index + 1) == '"' && _charAt(index + 2) == '"') {
                  index += 3;
                  return [
                    KdlToken.STRING,
                    _unescapeNonWs(_dedent(_unescapeWs(buffer)))
                  ];
                }
                buffer += c;
                index += 1;
                break;
              case null:
                throw "Unterminated multi-line string literal";
              default:
                buffer += c;
                index += 1;
                break;
            }
            break;
          case KdlTokenizerContext.rawstring:
            if (c == null) {
              throw "Unterminated rawstring literal";
            }

            if (c == '"') {
              var h = 0;
              while (_charAt(index + 1 + h) == '#' && h < rawstringHashes) {
                h += 1;
              }
              if (h == rawstringHashes) {
                index += 1 + h;
                return [KdlToken.RAWSTRING, buffer];
              }
            } else if (NEWLINES.contains(c)) {
              throw "Unexpected NEWLINE in single-line string";
            }

            buffer += c;
            index += 1;
            break;
          case KdlTokenizerContext.multiLineRawstring:
            if (c == null) {
              throw "Unterminated multi-line rawstring literal";
            }

            if (c == '"' &&
                _charAt(index + 1) == '"' &&
                _charAt(index + 2) == '"' &&
                _charAt(index + 3) == '#') {
              var h = 1;
              while (_charAt(index + 3 + h) == '#' && h < rawstringHashes) {
                h += 1;
              }
              if (h == rawstringHashes) {
                index += 3 + h;
                return [KdlToken.RAWSTRING, _dedent(buffer)];
              }
            }

            buffer += c;
            index += 1;
            break;
          case KdlTokenizerContext.decimal:
            if (c != null && RegExp(r"[0-9.\-+_eE]").hasMatch(c)) {
              index += 1;
              buffer += c;
            } else if (WHITESPACE.contains(c) ||
                NEWLINES.contains(c) ||
                c == null) {
              return _parseDecimal(buffer);
            } else {
              throw "Unexpected '$c'";
            }
            break;
          case KdlTokenizerContext.hexadecimal:
            if (c != null && RegExp(r"[0-9a-fA-F_]").hasMatch(c)) {
              index += 1;
              buffer += c;
            } else if (WHITESPACE.contains(c) ||
                NEWLINES.contains(c) ||
                c == null) {
              return _parseHexadecimal(buffer);
            } else {
              throw "Unexpected '$c'";
            }
            break;
          case KdlTokenizerContext.octal:
            if (c != null && RegExp(r"[0-7_]").hasMatch(c)) {
              index += 1;
              buffer += c;
            } else if (WHITESPACE.contains(c) ||
                NEWLINES.contains(c) ||
                c == null) {
              return _parseOctal(buffer);
            } else {
              throw "Unexpected '$c'";
            }
            break;
          case KdlTokenizerContext.binary:
            if (c != null && RegExp(r"[01_]").hasMatch(c)) {
              index += 1;
              buffer += c;
            } else if (WHITESPACE.contains(c) ||
                NEWLINES.contains(c) ||
                c == null) {
              return _parseBinary(buffer);
            } else {
              throw "Unexpected '$c'";
            }
            break;
          case KdlTokenizerContext.singleLineComment:
            if (NEWLINES.contains(c) || c == "\r") {
              _setContext(null);
              continue;
            } else if (c == null) {
              done = true;
              return [KdlToken.EOF, ''];
            } else {
              index += 1;
            }
            break;
          case KdlTokenizerContext.multiLineComment:
            var n = _charAt(index + 1);
            if (c == '/' && n == '*') {
              commentNesting += 1;
              index += 2;
            } else if (c == '*' && n == '/') {
              commentNesting -= 1;
              index += 2;
              if (commentNesting == 0) {
                _revertContext();
              }
            } else {
              index += 1;
            }
            break;
          case KdlTokenizerContext.whitespace:
            if (WHITESPACE.contains(c)) {
              index += 1;
              buffer += c;
            } else if (c == '=') {
              _setContext(KdlTokenizerContext.equals);
              buffer += c;
              index += 1;
            } else if (c == "\\") {
              var t = KdlTokenizer(str, start: index + 1);
              var la = t.nextToken();
              if (la[0] == KdlToken.NEWLINE || la[0] == KdlToken.EOF) {
                index = t.index;
                buffer += "${c}${la[1]}";
                continue;
              } else if (la[0] == KdlToken.WS) {
                var lan = t.nextToken();
                if (lan[0] == KdlToken.NEWLINE || lan[0] == KdlToken.EOF) {
                  index = t.index;
                  buffer += "${c}${la[1]}";
                  if (lan[0] == KdlToken.NEWLINE) {
                    buffer += "\n";
                  }
                  continue;
                }
              }
              throw "Unexpected '\\'";
            } else if (c == "/" && _charAt(index + 1) == '*') {
              _setContext(KdlTokenizerContext.multiLineComment);
              commentNesting = 1;
              index += 2;
            } else {
              return [KdlToken.WS, buffer];
            }
            break;
          case KdlTokenizerContext.equals:
            var t = KdlTokenizer(str, start: index);
            var la = t.nextToken();
            if (la[0] == KdlToken.WS) {
              buffer += la[1];
              index = t.index;
            }
            return [KdlToken.EQUALS, buffer];
          case null:
            throw "Unexpected null context";
        }
      }
    }
  }

  _charAt(int i) {
    if (i < 0 || i >= str.runes.length) {
      return null;
    }
    var char = String.fromCharCode(str.runes.elementAt(i));
    if (FORBIDDEN.contains(char)) {
      throw "Forbidden character: ${char}";
    }
    return char;
  }

  _revertContext() {
    context = previousContext;
    previousContext = null;
  }

  _expectNewline(int i) {
    var c = _charAt(i);
    if (c == "\r") {
      var n = _charAt(i + 1);
      if (n == "\n") {
        return "${c}${n}";
      }
    } else if (!NEWLINES.contains(c)) {
      throw "Expected NEWLINE, found '${c}'";
    }
    return c;
  }

  _integerContext(String n) {
    switch (n) {
      case 'b':
        return KdlTokenizerContext.binary;
      case 'o':
        return KdlTokenizerContext.octal;
      case 'x':
        return KdlTokenizerContext.hexadecimal;
    }
  }

  _parseDecimal(String s) {
    try {
      if (RegExp("[.eE]").hasMatch(s)) {
        _checkFloat(s);
        return [KdlToken.DECIMAL, BigDecimal.parse(_munchUnderscores(s))];
      }
      _checkInt(s);
      return [KdlToken.INTEGER, _parseInteger(_munchUnderscores(s), 10)];
    } catch (e) {
      if (NON_INITIAL_IDENTIFIER_CHARS
              .contains(String.fromCharCode(s.runes.first)) ||
          s.runes.skip(1).any(
              (c) => NON_IDENTIFIER_CHARS.contains(String.fromCharCode(c)))) {
        throw e;
      }
      return [KdlToken.IDENT, s];
    }
  }

  _checkFloat(String s) {
    if (!RegExp(r"^[+-]?[0-9][0-9_]*(\.[0-9][0-9_]*)?([eE][+-]?[0-9][0-9_]*)?$")
        .hasMatch(s)) {
      throw "Invalid float: ${s}";
    }
  }

  _checkInt(String s) {
    if (!RegExp(r"^[+-]?[0-9][0-9_]*$").hasMatch(s)) {
      throw "Invalid integer: ${s}";
    }
  }

  _parseHexadecimal(String s) {
    if (!RegExp(r"^[+-]?[0-9a-fA-F][0-9a-fA-F_]*$").hasMatch(s))
      throw "Invalid hexadecimal: ${s}";
    return [KdlToken.INTEGER, _parseInteger(_munchUnderscores(s), 16)];
  }

  _parseOctal(String s) {
    if (!RegExp(r"^[+-]?[0-7][0-7_]*$").hasMatch(s))
      throw "Invalid octal: ${s}";
    return [KdlToken.INTEGER, _parseInteger(_munchUnderscores(s), 8)];
  }

  _parseBinary(String s) {
    if (!RegExp(r"^[+-]?[01][01_]*$").hasMatch(s)) throw "Invalid binary: ${s}";
    return [KdlToken.INTEGER, _parseInteger(_munchUnderscores(s), 2)];
  }

  _munchUnderscores(String s) {
    return s.replaceAll('_', '');
  }

  _unescapeWs(String string) {
    return string.replaceAllMapped(RegExp(r"\\(\\|\s+)"), (match) {
      var m = match.group(0);
      switch (m) {
        case r'\\':
          return r'\\';
        default:
          return '';
      }
    });
  }

  static final UNESCAPE_WS =
      "[${WHITESPACE.map(RegExp.escape).join()}${NEWLINES.map(RegExp.escape).join()}\\r]+";
  static final UNESCAPE = RegExp("\\\\(?:${UNESCAPE_WS}|[^u])");
  static final UNESCAPE_NON_WS = RegExp(r"\\(?:[^u])");

  _unescapeNonWs(String string) {
    return _unescapeRgx(string, UNESCAPE_NON_WS);
  }

  _unescape(String string) {
    return _unescapeRgx(string, UNESCAPE);
  }

  _unescapeRgx(String string, RegExp rgx) {
    return string.replaceAllMapped(rgx, (match) {
      return _replaceEsc(match.group(0));
    }).replaceAllMapped(RegExp(r"\\u\{[0-9a-fA-F]{1,6}\}"), (match) {
      String m = match.group(0) ?? '';
      int i = int.parse(m.substring(3, m.length - 1), radix: 16);
      if (i < 0 || i > 0x10FFFF || (i >= 0xD800 && i <= 0xDFFF)) {
        throw "Invalid code point ${m}";
      }
      return String.fromCharCode(i);
    });
  }

  _replaceEsc(String? m) {
    switch (m) {
      case r'\n':
        return "\n";
      case r'\r':
        return "\r";
      case r'\t':
        return "\t";
      case r'\\':
        return "\\";
      case r'\"':
        return "\"";
      case r'\b':
        return "\b";
      case r'\f':
        return "\f";
      case "\\\n":
        return "";
      case r'\s':
        return ' ';
      default:
        if (m != null && RegExp("\\\\${UNESCAPE_WS}").hasMatch(m)) return '';
        throw "Unexpected escape '${m}'";
    }
  }

  _parseInteger(String string, int radix) {
    try {
      return int.parse(string, radix: radix);
    } catch (FormatException) {
      return BigInt.parse(string, radix: radix);
    }
  }

  _dedent(String string) {
    var [...lines, indent] = string.split(NEWLINES_PATTERN);
    if (!WS_STAR.hasMatch(indent)) {
      throw "Invalid multiline string final line";
    }

    var valid = RegExp("${RegExp.escape(indent)}(.*)");

    return lines.map((line) {
      if (WS_STAR.hasMatch(line)) {
        return '';
      }
      var m = valid.matchAsPrefix(line);
      if (m != null) {
        return m.group(1);
      }
      throw "Invalid multiline string indentation";
    }).join("\n");
  }
}
