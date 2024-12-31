import 'dart:collection';
import 'package:big_decimal/big_decimal.dart';
import 'package:kdl/src/exception.dart';

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

enum KdlTerm {
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

class KdlToken {
  KdlTerm type;
  dynamic value;
  int? line;
  int? column;

  KdlToken(this.type, this.value, [this.line = null, this.column = null]);

  @override
  bool operator ==(other) {
    if (other is KdlToken) {
      return type == other.type &&
          value == other.value &&
          (line == null || other.line == null || line == other.line) &&
          (column == null || other.column == null || column == other.column);
    }
    return false;
  }

  String toString() {
    return "KdlToken($type, ${value.toString()}, $line, $column)";
  }
}

class KdlTokenizer {
  static final SYMBOLS = {
    '{': KdlTerm.LBRACE,
    '}': KdlTerm.RBRACE,
    ';': KdlTerm.SEMICOLON,
    '=': KdlTerm.EQUALS
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

  static const NEWLINES = [
    "\u000A",
    "\u0085",
    "\u000B",
    "\u000C",
    "\u2028",
    "\u2029"
  ];
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
  KdlTokenizerContext? _context = null;
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
  int line = 1;
  int column = 1;
  int lineAtStart = 1;
  int columnAtStart = 1;

  KdlTokenizer(String str, {int this.start = 0}) {
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

  allTokens() {
    List a = [];
    while (!done) {
      a.add(nextToken());
    }
    return a;
  }

  set context(KdlTokenizerContext? ctx) {
    previousContext = _context;
    _context = ctx;
  }

  KdlTokenizerContext? get context => _context;

  KdlToken peekToken() {
    if (peekedTokens.isEmpty) {
      peekedTokens.add(readToken());
    }
    return peekedTokens.first;
  }

  KdlToken peekTokenAfterNext() {
    if (peekedTokens.isEmpty) {
      peekedTokens.add(readToken());
      peekedTokens.add(readToken());
    } else if (peekedTokens.length == 1) {
      peekedTokens.add(readToken());
    }
    return peekedTokens.elementAt(1);
  }

  KdlToken nextToken() {
    if (peekedTokens.isNotEmpty) {
      return peekedTokens.removeFirst();
    } else {
      return readToken();
    }
  }

  KdlToken readToken() {
    context = null;
    previousContext = null;
    lineAtStart = line;
    columnAtStart = column;
    while (true) {
      var c = char(index);
      if (context == null) {
        if (c == null) {
          if (done) {
            return token(KdlTerm.EOF, null);
          }
          done = true;
          return token(KdlTerm.EOF, '');
        } else if (c == '"') {
          if (char(index + 1) == '"' && char(index + 2) == '"') {
            String nl = expectNewline(index + 3);
            context = KdlTokenizerContext.multiLineString;
            buffer = '';
            traverse(3 + nl.runes.length);
          } else {
            context = KdlTokenizerContext.string;
            buffer = '';
            traverse(1);
          }
        } else if (c == '#') {
          if (char(index + 1) == '"') {
            if (char(index + 2) == '"' && char(index + 3) == '"') {
              String nl = expectNewline(index + 4);
              context = KdlTokenizerContext.multiLineRawstring;
              rawstringHashes = 1;
              buffer = '';
              traverse(4 + nl.runes.length);
              continue;
            } else {
              context = KdlTokenizerContext.rawstring;
              traverse(2);
              rawstringHashes = 1;
              buffer = '';
              continue;
            }
          } else if (char(index + 1) == '#') {
            var i = index + 1;
            rawstringHashes = 1;
            while (char(i) == '#') {
              rawstringHashes += 1;
              i += 1;
            }
            if (char(i) == '"') {
              if (char(i + 1) == '"' && char(i + 2) == '"') {
                String nl = expectNewline(i + 3);
                context = KdlTokenizerContext.multiLineRawstring;
                buffer = '';
                traverse(rawstringHashes + 3 + nl.runes.length);
                continue;
              } else {
                context = KdlTokenizerContext.rawstring;
                traverse(rawstringHashes + 1);
                buffer = '';
                continue;
              }
            }
          }
          context = KdlTokenizerContext.keyword;
          buffer = c;
          traverse(1);
        } else if (c == '-') {
          var n = char(index + 1);
          var n2 = char(index + 2);
          if (n != null && RegExp(r"[0-9]").hasMatch(n)) {
            if (n == '0' && n2 != null && RegExp(r"[box]").hasMatch(n2)) {
              context = integerContext(n2);
              traverse(2);
            } else {
              context = KdlTokenizerContext.decimal;
            }
          } else {
            context = KdlTokenizerContext.ident;
          }
          buffer = c;
          traverse(1);
        } else if (RegExp(r"[0-9+]").hasMatch(c)) {
          var n = char(index + 1);
          var n2 = char(index + 2);
          if (c == '0' && n != null && RegExp("[box]").hasMatch(n)) {
            buffer = '';
            context = integerContext(n);
            traverse(2);
          } else if (c == '+' && n == '0' && RegExp("[box]").hasMatch(n2)) {
            buffer = c;
            context = integerContext(n2);
            traverse(3);
          } else {
            buffer = c;
            context = KdlTokenizerContext.decimal;
            traverse(1);
          }
        } else if (c == "\\") {
          var t = KdlTokenizer(str, start: index + 1);
          var la = t.nextToken();
          if (la.type == KdlTerm.NEWLINE || la.type == KdlTerm.EOF) {
            buffer = "${c}${la.value}";
            context = KdlTokenizerContext.whitespace;
            traverseTo(t.index);
            continue;
          } else if (la.type == KdlTerm.WS) {
            var lan = t.nextToken();
            if (lan.type == KdlTerm.NEWLINE || lan.type == KdlTerm.EOF) {
              buffer = "${c}${la.value}";
              if (lan.type == KdlTerm.NEWLINE) buffer += "\n";
              context = KdlTokenizerContext.whitespace;
              traverseTo(t.index);
              continue;
            }
          }
          fail("Unexpected '\\'");
        } else if (c == '=') {
          buffer = c;
          context = KdlTokenizerContext.equals;
          traverse(1);
        } else if (SYMBOLS.containsKey(c)) {
          traverse(1);
          return KdlToken(SYMBOLS[c]!, c);
        } else if (c == "\r" || NEWLINES.contains(c)) {
          String nl = expectNewline(index);
          traverse(nl.runes.length);
          return token(KdlTerm.NEWLINE, nl);
        } else if (c == "/") {
          var n = char(index + 1);
          if (n == '/') {
            if (inType || lastToken?.type == KdlTerm.RPAREN)
              fail("Unexpected '/'");
            context = KdlTokenizerContext.singleLineComment;
            traverse(2);
          } else if (n == '*') {
            commentNesting = 1;
            context = KdlTokenizerContext.multiLineComment;
            traverse(2);
          } else if (n == '-') {
            traverse(2);
            return token(KdlTerm.SLASHDASH, '/-');
          } else {
            fail("Unexpected character '${c}'");
          }
        } else if (WHITESPACE.contains(c)) {
          buffer = c;
          context = KdlTokenizerContext.whitespace;
          traverse(1);
        } else if (!NON_INITIAL_IDENTIFIER_CHARS.contains(c)) {
          buffer = c;
          context = KdlTokenizerContext.ident;
          traverse(1);
        } else if (c == '(') {
          inType = true;
          traverse(1);
          return token(KdlTerm.LPAREN, c);
        } else if (c == ')') {
          inType = false;
          traverse(1);
          return token(KdlTerm.RPAREN, c);
        } else {
          fail("Unexpected character '${c}'");
        }
      } else {
        switch (context) {
          case KdlTokenizerContext.ident:
            if (!NON_IDENTIFIER_CHARS.contains(c)) {
              buffer += c;
              traverse(1);
              break;
            } else {
              if (['true', 'false', 'null', 'inf', '-inf', 'nan']
                  .contains(buffer)) {
                fail("Identifier cannot be a literal");
              } else if (RegExp(r"^\.\d").hasMatch(buffer)) {
                fail("Identifier cannot look like an illegal float");
              } else {
                return token(KdlTerm.IDENT, buffer);
              }
            }
          case KdlTokenizerContext.keyword:
            if (c != null && RegExp(r"[a-z\-]").hasMatch(c)) {
              buffer += c;
              traverse(1);
              break;
            } else {
              switch (buffer) {
                case '#true':
                  return token(KdlTerm.TRUE, true);
                case '#false':
                  return token(KdlTerm.FALSE, false);
                case '#null':
                  return token(KdlTerm.NULL, null);
                case '#inf':
                  return token(KdlTerm.DOUBLE, double.infinity);
                case '#-inf':
                  return token(KdlTerm.DOUBLE, -double.infinity);
                case '#nan':
                  return token(KdlTerm.DOUBLE, double.nan);
                default:
                  fail("Unknown keyword ${buffer}");
              }
            }
          case KdlTokenizerContext.string:
            switch (c) {
              case '\\':
                buffer += c;
                var c2 = char(index + 1);
                buffer += c2;
                if (NEWLINES.contains(c2)) {
                  var i = 2;
                  while (NEWLINES.contains(c2 = char(index + i))) {
                    buffer += c2;
                    i += 1;
                  }
                  traverse(i);
                } else {
                  traverse(2);
                }
                break;
              case '"':
                traverse(1);
                return token(KdlTerm.STRING, unescape(buffer));
              case '':
              case null:
                fail("Unterminated string literal");
              default:
                if (NEWLINES.contains(c)) {
                  fail("Unexpected NEWLINE in single-line string");
                }
                buffer += c;
                traverse(1);
                break;
            }
            break;
          case KdlTokenizerContext.multiLineString:
            switch (c) {
              case '\\':
                buffer += c;
                buffer += char(index + 1);
                traverse(2);
                break;
              case '"':
                if (char(index + 1) == '"' && char(index + 2) == '"') {
                  traverse(3);
                  return token(KdlTerm.STRING,
                      unescapeNonWs(dedent(unescapeWs(buffer))));
                }
                buffer += c;
                traverse(1);
                break;
              case null:
                fail("Unterminated multi-line string literal");
              default:
                buffer += c;
                traverse(1);
                break;
            }
            break;
          case KdlTokenizerContext.rawstring:
            if (c == null) {
              fail("Unterminated rawstring literal");
            }

            if (c == '"') {
              var h = 0;
              while (char(index + 1 + h) == '#' && h < rawstringHashes) {
                h += 1;
              }
              if (h == rawstringHashes) {
                traverse(1 + h);
                return token(KdlTerm.RAWSTRING, buffer);
              }
            } else if (NEWLINES.contains(c)) {
              fail("Unexpected NEWLINE in single-line string");
            }

            buffer += c;
            traverse(1);
            break;
          case KdlTokenizerContext.multiLineRawstring:
            if (c == null) {
              fail("Unterminated multi-line rawstring literal");
            }

            if (c == '"' &&
                char(index + 1) == '"' &&
                char(index + 2) == '"' &&
                char(index + 3) == '#') {
              var h = 1;
              while (char(index + 3 + h) == '#' && h < rawstringHashes) {
                h += 1;
              }
              if (h == rawstringHashes) {
                traverse(3 + h);
                return token(KdlTerm.RAWSTRING, dedent(buffer));
              }
            }

            buffer += c;
            traverse(1);
            break;
          case KdlTokenizerContext.decimal:
            if (c != null && RegExp(r"[0-9.\-+_eE]").hasMatch(c)) {
              buffer += c;
              traverse(1);
            } else if (WHITESPACE.contains(c) ||
                NEWLINES.contains(c) ||
                c == null) {
              return parseDecimal(buffer);
            } else {
              fail("Unexpected '$c'");
            }
            break;
          case KdlTokenizerContext.hexadecimal:
            if (c != null && RegExp(r"[0-9a-fA-F_]").hasMatch(c)) {
              buffer += c;
              traverse(1);
            } else if (WHITESPACE.contains(c) ||
                NEWLINES.contains(c) ||
                c == null) {
              return parseHexadecimal(buffer);
            } else {
              fail("Unexpected '$c'");
            }
            break;
          case KdlTokenizerContext.octal:
            if (c != null && RegExp(r"[0-7_]").hasMatch(c)) {
              buffer += c;
              traverse(1);
            } else if (WHITESPACE.contains(c) ||
                NEWLINES.contains(c) ||
                c == null) {
              return parseOctal(buffer);
            } else {
              fail("Unexpected '$c'");
            }
            break;
          case KdlTokenizerContext.binary:
            if (c != null && RegExp(r"[01_]").hasMatch(c)) {
              buffer += c;
              traverse(1);
            } else if (WHITESPACE.contains(c) ||
                NEWLINES.contains(c) ||
                c == null) {
              return parseBinary(buffer);
            } else {
              fail("Unexpected '$c'");
            }
            break;
          case KdlTokenizerContext.singleLineComment:
            if (NEWLINES.contains(c) || c == "\r") {
              context = null;
              columnAtStart = column;
              continue;
            } else if (c == null) {
              done = true;
              return token(KdlTerm.EOF, '');
            } else {
              traverse(1);
            }
            break;
          case KdlTokenizerContext.multiLineComment:
            var n = char(index + 1);
            if (c == '/' && n == '*') {
              commentNesting += 1;
              traverse(2);
            } else if (c == '*' && n == '/') {
              commentNesting -= 1;
              traverse(2);
              if (commentNesting == 0) {
                revertContext();
              }
            } else {
              traverse(1);
            }
            break;
          case KdlTokenizerContext.whitespace:
            if (WHITESPACE.contains(c)) {
              buffer += c;
              traverse(1);
            } else if (c == '=') {
              buffer += c;
              context = KdlTokenizerContext.equals;
              traverse(1);
            } else if (c == "\\") {
              var t = KdlTokenizer(str, start: index + 1);
              var la = t.nextToken();
              if (la.type == KdlTerm.NEWLINE || la.type == KdlTerm.EOF) {
                buffer += "${c}${la.value}";
                traverseTo(t.index);
                continue;
              } else if (la.type == KdlTerm.WS) {
                var lan = t.nextToken();
                if (lan.type == KdlTerm.NEWLINE || lan.type == KdlTerm.EOF) {
                  buffer += "${c}${la.value}";
                  if (lan.type == KdlTerm.NEWLINE) buffer += "\n";
                  traverseTo(t.index);
                  continue;
                }
              }
              fail("Unexpected '\\'");
            } else if (c == "/" && char(index + 1) == '*') {
              commentNesting = 1;
              context = KdlTokenizerContext.multiLineComment;
              traverse(2);
            } else {
              return token(KdlTerm.WS, buffer);
            }
            break;
          case KdlTokenizerContext.equals:
            var t = KdlTokenizer(str, start: index);
            var la = t.nextToken();
            if (la.type == KdlTerm.WS) {
              buffer += la.value;
              traverseTo(t.index);
            }
            return token(KdlTerm.EQUALS, buffer);
          case null:
            fail("Unexpected null context");
        }
      }
    }
  }

  char(int i) {
    if (i < 0 || i >= str.runes.length) {
      return null;
    }
    var char = String.fromCharCode(str.runes.elementAt(i));
    if (FORBIDDEN.contains(char)) {
      fail("Forbidden character: ${char}");
    }
    return char;
  }

  KdlToken token(KdlTerm type, value) {
    return lastToken = KdlToken(type, value, lineAtStart, columnAtStart);
  }

  void traverse([int n = 1]) {
    for (int i = 0; i < n; i++) {
      var c = char(index + i);
      if (c == "\r") {
        column = 1;
      } else if (NEWLINES.contains(c)) {
        line += 1;
        column = 1;
      } else {
        column += 1;
      }
    }
    index += n;
  }

  void traverseTo(i) {
    traverse(i - index);
  }

  void fail(message) {
    throw KdlParseException(message, line, column);
  }

  void revertContext() {
    _context = previousContext;
    previousContext = null;
  }

  String expectNewline(int i) {
    var c = char(i);
    if (c == "\r") {
      var n = char(i + 1);
      if (n == "\n") {
        return "${c}${n}";
      }
    } else if (!NEWLINES.contains(c)) {
      fail("Expected NEWLINE, found '${c}'");
    }
    return c;
  }

  integerContext(String n) {
    switch (n) {
      case 'b':
        return KdlTokenizerContext.binary;
      case 'o':
        return KdlTokenizerContext.octal;
      case 'x':
        return KdlTokenizerContext.hexadecimal;
    }
  }

  parseDecimal(String s) {
    try {
      if (RegExp("[.eE]").hasMatch(s)) {
        checkFloat(s);
        return KdlToken(KdlTerm.DECIMAL, BigDecimal.parse(munchUnderscores(s)));
      }
      checkInt(s);
      return token(KdlTerm.INTEGER, parseInteger(munchUnderscores(s), 10));
    } catch (e) {
      if (NON_INITIAL_IDENTIFIER_CHARS
              .contains(String.fromCharCode(s.runes.first)) ||
          s.runes.skip(1).any(
              (c) => NON_IDENTIFIER_CHARS.contains(String.fromCharCode(c)))) {
        throw e;
      }
      return token(KdlTerm.IDENT, s);
    }
  }

  checkFloat(String s) {
    if (!RegExp(r"^[+-]?[0-9][0-9_]*(\.[0-9][0-9_]*)?([eE][+-]?[0-9][0-9_]*)?$")
        .hasMatch(s)) {
      fail("Invalid float: ${s}");
    }
  }

  checkInt(String s) {
    if (!RegExp(r"^[+-]?[0-9][0-9_]*$").hasMatch(s)) {
      fail("Invalid integer: ${s}");
    }
  }

  parseHexadecimal(String s) {
    if (!RegExp(r"^[+-]?[0-9a-fA-F][0-9a-fA-F_]*$").hasMatch(s))
      fail("Invalid hexadecimal: ${s}");
    return token(KdlTerm.INTEGER, parseInteger(munchUnderscores(s), 16));
  }

  parseOctal(String s) {
    if (!RegExp(r"^[+-]?[0-7][0-7_]*$").hasMatch(s))
      fail("Invalid octal: ${s}");
    return token(KdlTerm.INTEGER, parseInteger(munchUnderscores(s), 8));
  }

  parseBinary(String s) {
    if (!RegExp(r"^[+-]?[01][01_]*$").hasMatch(s)) fail("Invalid binary: ${s}");
    return token(KdlTerm.INTEGER, parseInteger(munchUnderscores(s), 2));
  }

  munchUnderscores(String s) {
    return s.replaceAll('_', '');
  }

  unescapeWs(String string) {
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

  unescapeNonWs(String string) {
    return unescapeRgx(string, UNESCAPE_NON_WS);
  }

  unescape(String string) {
    return unescapeRgx(string, UNESCAPE);
  }

  unescapeRgx(String string, RegExp rgx) {
    return string.replaceAllMapped(rgx, (match) {
      return replaceEsc(match.group(0));
    }).replaceAllMapped(RegExp(r"\\u\{[0-9a-fA-F]{1,6}\}"), (match) {
      String m = match.group(0) ?? '';
      int i = int.parse(m.substring(3, m.length - 1), radix: 16);
      if (i < 0 || i > 0x10FFFF || (i >= 0xD800 && i <= 0xDFFF)) {
        fail("Invalid code point ${m}");
      }
      return String.fromCharCode(i);
    });
  }

  replaceEsc(String? m) {
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
        fail("Unexpected escape '${m}'");
    }
  }

  parseInteger(String string, int radix) {
    try {
      return int.parse(string, radix: radix);
    } catch (FormatException) {
      return BigInt.parse(string, radix: radix);
    }
  }

  dedent(String string) {
    var [...lines, indent] = string.split(NEWLINES_PATTERN);
    if (!WS_STAR.hasMatch(indent)) {
      fail("Invalid multiline string final line");
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
      fail("Invalid multiline string indentation");
    }).join("\n");
  }
}
