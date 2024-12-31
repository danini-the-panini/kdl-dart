import 'package:big_decimal/big_decimal.dart';
import 'package:kdl/src/tokenizer.dart';

class KdlV1Tokenizer extends KdlTokenizer {
  static final symbols = {
    '{': KdlTerm.lbrace,
    '}': KdlTerm.rbrace,
    '(': KdlTerm.lparen,
    ')': KdlTerm.rparen,
    ';': KdlTerm.semicolon,
    '=': KdlTerm.equals
  };

  static const newliens = ["\u000A", "\u0085", "\u000C", "\u2028", "\u2029"];
  static final newlinesPattern =
      RegExp("${newliens.map(RegExp.escape).join('|')}|\\r\\n?");

  static final nonIdentigierChars = [
    null,
    ...KdlTokenizer.whitespace,
    ...newliens,
    ...symbols.keys,
    "\r",
    "\\",
    "<",
    ">",
    "[",
    "]",
    '"',
    ",",
    "/",
    ...charRange(0x0000, 0x0020),
  ];
  static final nonInitialIdentifierChars = [
    ...nonIdentigierChars,
    List.generate(10, (index) => index.toString())
  ];

  KdlV1Tokenizer(super.str);

  static final versionPattern = RegExp(
      "\\/-${KdlTokenizer.ws}*kdl-version${KdlTokenizer.ws}+(\\d+)${KdlTokenizer.ws}*${newlinesPattern.pattern}");

  @override
  versionDirective() {
    var match = versionPattern.matchAsPrefix(str);
    if (match == null) return null;
    var m = match.group(1);
    if (m == null) return null;
    return int.parse(m);
  }

  @override
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
            return token(KdlTerm.eof, null);
          }
          done = true;
          return token(KdlTerm.eof, '');
        } else if (c == '"') {
          context = KdlTokenizerContext.string;
          buffer = '';
          traverse(1);
        } else if (c == 'r') {
          if (char(index + 1) == '"') {
            context = KdlTokenizerContext.rawstring;
            traverse(2);
            rawstringHashes = 0;
            buffer = '';
            continue;
          } else if (char(index + 1) == '#') {
            var i = index + 1;
            rawstringHashes = 0;
            while (char(i) == '#') {
              rawstringHashes += 1;
              i += 1;
            }
            if (char(i) == '"') {
              context = KdlTokenizerContext.rawstring;
              traverse(rawstringHashes + 2);
              buffer = '';
              continue;
            }
          }
          context = KdlTokenizerContext.ident;
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
          if (la.type == KdlTerm.newline || la.type == KdlTerm.eof) {
            buffer = "$c${la.value}";
            context = KdlTokenizerContext.whitespace;
            traverseTo(t.index);
            continue;
          } else if (la.type == KdlTerm.whitespace) {
            var lan = t.nextToken();
            if (lan.type == KdlTerm.newline || lan.type == KdlTerm.eof) {
              buffer = "$c${la.value}";
              if (lan.type == KdlTerm.newline) buffer += "\n";
              context = KdlTokenizerContext.whitespace;
              traverseTo(t.index);
              continue;
            }
          }
          fail("Unexpected '\\'");
        } else if (symbols.containsKey(c)) {
          if (c == '(') {
            inType = true;
          } else if (c == ')') {
            inType = false;
          }
          traverse(1);
          return token(symbols[c]!, c);
        } else if (c == "\r" || newliens.contains(c)) {
          String nl = expectNewline(index);
          traverse(nl.runes.length);
          return token(KdlTerm.newline, nl);
        } else if (c == "/") {
          var n = char(index + 1);
          if (n == '/') {
            if (inType || lastToken?.type == KdlTerm.rparen) {
              fail("Unexpected '/'");
            }
            context = KdlTokenizerContext.singleLineComment;
            traverse(2);
          } else if (n == '*') {
            if (inType || lastToken?.type == KdlTerm.rparen) {
              fail("Unexpected '/'");
            }
            commentNesting = 1;
            context = KdlTokenizerContext.multiLineComment;
            traverse(2);
          } else if (n == '-') {
            traverse(2);
            return token(KdlTerm.slashdash, '/-');
          } else {
            fail("Unexpected character '$c'");
          }
        } else if (KdlTokenizer.whitespace.contains(c)) {
          buffer = c;
          context = KdlTokenizerContext.whitespace;
          traverse(1);
        } else if (!nonInitialIdentifierChars.contains(c)) {
          buffer = c;
          context = KdlTokenizerContext.ident;
          traverse(1);
        } else {
          fail("Unexpected character '$c'");
        }
      } else {
        switch (context) {
          case KdlTokenizerContext.ident:
            if (!nonIdentigierChars.contains(c)) {
              buffer += c;
              traverse(1);
              break;
            } else {
              switch (buffer) {
                case 'true':
                  return token(KdlTerm.trueKeyword, true);
                case 'false':
                  return token(KdlTerm.falseKeyword, false);
                case 'null':
                  return token(KdlTerm.nullKeyword, null);
                default:
                  return token(KdlTerm.ident, buffer);
              }
            }
          case KdlTokenizerContext.string:
            switch (c) {
              case '\\':
                buffer += c;
                var c2 = char(index + 1);
                buffer += c2;
                if (newliens.contains(c2)) {
                  var i = 2;
                  while (newliens.contains(c2 = char(index + i))) {
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
                return token(KdlTerm.string, unescape(buffer));
              case '':
              case null:
                fail("Unterminated string literal");
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
                return token(KdlTerm.rawstring, buffer);
              }
            }
            buffer += c;
            traverse(1);
            break;
          case KdlTokenizerContext.decimal:
            if (c != null && RegExp(r"[0-9.\-+_eE]").hasMatch(c)) {
              buffer += c;
              traverse(1);
            } else if (KdlTokenizer.whitespace.contains(c) ||
                newliens.contains(c) ||
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
            } else if (KdlTokenizer.whitespace.contains(c) ||
                newliens.contains(c) ||
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
            } else if (KdlTokenizer.whitespace.contains(c) ||
                newliens.contains(c) ||
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
            } else if (KdlTokenizer.whitespace.contains(c) ||
                newliens.contains(c) ||
                c == null) {
              return parseBinary(buffer);
            } else {
              fail("Unexpected '$c'");
            }
            break;
          case KdlTokenizerContext.singleLineComment:
            if (newliens.contains(c) || c == "\r") {
              context = null;
              columnAtStart = column;
              continue;
            } else if (c == null) {
              done = true;
              return token(KdlTerm.eof, '');
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
            if (KdlTokenizer.whitespace.contains(c)) {
              buffer += c;
              traverse(1);
            } else if (c == "\\") {
              var t = KdlTokenizer(str, start: index + 1);
              var la = t.nextToken();
              if (la.type == KdlTerm.newline || la.type == KdlTerm.eof) {
                buffer += "$c${la.value}";
                traverseTo(t.index);
                continue;
              } else if (la.type == KdlTerm.whitespace) {
                var lan = t.nextToken();
                if (lan.type == KdlTerm.newline || lan.type == KdlTerm.eof) {
                  buffer += "$c${la.value}";
                  if (lan.type == KdlTerm.newline) buffer += "\n";
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
              return token(KdlTerm.whitespace, buffer);
            }
            break;
          case null:
            fail("Unexpected null context");
          default:
            fail("Unknown context $context");
        }
      }
    }
  }

  @override
  parseDecimal(String s) {
    if (RegExp("[.eE]").hasMatch(s)) {
      checkFloat(s);
      return token(KdlTerm.decimal, BigDecimal.parse(munchUnderscores(s)));
    }
    checkInt(s);
    return token(KdlTerm.integer, parseInteger(munchUnderscores(s), 10));
  }

  @override
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
      case r'\/':
        return '/';
      default:
        if (m != null &&
            RegExp("\\\\${KdlTokenizer.unescapeWsPattern}").hasMatch(m)) {
          return '';
        }
        fail("Unexpected escape '$m'");
    }
  }
}
