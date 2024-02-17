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

List charRange(int from, int to) => List.generate(to - from + 1, (i) => String.fromCharCode(i + from));

String debom(String str) {
  if (str.startsWith("\uFEFF")) {
    return str.substring(1);
  }

  return str;
}

class KdlTokenizer {
  static const EQUALS = ['=', '﹦', '＝', '🟰'];

  static final SYMBOLS = {
    '{': KdlToken.LBRACE,
    '}': KdlToken.RBRACE,
    ';': KdlToken.SEMICOLON,
    ...Map.fromIterable(EQUALS, key: (item) => item, value: (item) => KdlToken.EQUALS)
  };

  static const WHITESPACE = [
    "\u0009", "\u000B", "\u0020", "\u00A0",
    "\u1680", "\u2000", "\u2001", "\u2002",
    "\u2003", "\u2004", "\u2005", "\u2006",
    "\u2007", "\u2008", "\u2009", "\u200A",
    "\u202F", "\u205F", "\u3000" 
  ];

  static const NEWLINES = ["\u000A", "\u0085", "\u000C", "\u2028", "\u2029"];

  static final NON_IDENTIFIER_CHARS = [
    null,
    ...WHITESPACE,
    ...NEWLINES,
    ...SYMBOLS.keys,
    "\r", "\\", "[", "]", "(", ")", '"', "/", "#",
    ...charRange(0x000, 0x0020),
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

  KdlTokenizer(String str, { int start = 0 }) {
    this.str = debom(str);
    this.index = start;
    this.start = start;
  }

  reset() {
    this.index = this.start;
  }

  allTokens() {
    List a = [];
    while (!this.done) {
      a.add(this.nextToken());
    }
    return a;
  }

  _setContext(KdlTokenizerContext? ctx) {
    this.previousContext = this.context;
    this.context = ctx;
  }

  peekToken() {
    if (this.peekedTokens.isEmpty) {
      this.peekedTokens.add(_nextToken());
    }
    return this.peekedTokens.first;
  }

  peekTokenAfterNext() {
    if (this.peekedTokens.isEmpty) {
      this.peekedTokens.add(_nextToken());
      this.peekedTokens.add(_nextToken());
    } else if (this.peekedTokens.length == 1) {
      this.peekedTokens.add(_nextToken());
    }
    return this.peekedTokens.elementAt(1);
  }

  nextToken() {
    if (this.peekedTokens.isNotEmpty) {
      return this.peekedTokens.removeFirst();
    } else {
      return _nextToken();
    } 
  }

  _nextToken() {
    var token = this._readNextToken();
    if (token[0] != false) lastToken = token[0];
    return token;
  }

  _readNextToken() {
    this.context = null;
    this.previousContext = null;
    while (true) {
      var c = _charAt(this.index);
      if (this.context == null) {
        if (c == '"') {
          if (_charAt(this.index + 1) == "\n") {
            _setContext(KdlTokenizerContext.multiLineString);
            this.buffer = '';
            this.index += 2;
          } else {
            _setContext(KdlTokenizerContext.string);
            this.buffer = '';
            this.index += 1;
          }
        } else if (c == '#') {
          if (_charAt(this.index + 1) == '"') {
            if (_charAt(this.index + 2) == "\n") {
              _setContext(KdlTokenizerContext.multiLineRawstring);
              this.rawstringHashes = 1;
              this.buffer = '';
              this.index += 3;
              continue;
            } else {
              _setContext(KdlTokenizerContext.rawstring);
              this.index += 2;
              this.rawstringHashes = 1;
              this.buffer = '';
              continue;
            }
          } else if (_charAt(this.index + 1) == '#') {
            var i = this.index + 1;
            this.rawstringHashes = 1;
            while (_charAt(i) == '#') {
              this.rawstringHashes += 1;
              i += 1;
            }
            if (_charAt(i) == '"') {
              if (_charAt(i + 1) == "\n") {
                _setContext(KdlTokenizerContext.multiLineRawstring);
                this.index = i + 2;
                this.buffer = '';
                continue;
              } else {
                _setContext(KdlTokenizerContext.rawstring);
                this.index = i + 1;
                this.buffer = '';
                continue;
              }
            }
          }
          _setContext(KdlTokenizerContext.keyword);
          this.buffer = c;
          this.index += 1;
        } else if (c == '-') {
          var n = _charAt(this.index + 1);
          if (n != null && RegExp(r"[0-9]").hasMatch(n)) {
            _setContext(KdlTokenizerContext.decimal);
          } else {
            _setContext(KdlTokenizerContext.ident);
          }
          this.buffer = c;
          this.index += 1;
        } else if (c != null && RegExp(r"[0-9+]").hasMatch(c)) {
          var n = _charAt(this.index + 1);
          var n2 = _charAt(this.index + 2);
          if (c == '0' && n != null && RegExp("[box]").hasMatch(n)) {
            this.index += 2;
            this.buffer = '';
            _setContext(_integerContext(n));
          } else if ((c == '-' || c == '+') && n == '0' && RegExp("[box]").hasMatch(n2)) {
            this.index += 3;
            this.buffer = c;
            _setContext(_integerContext(n2));
          } else {
            _setContext(KdlTokenizerContext.decimal);
            this.index += 1;
            this.buffer = c;
          }
        } else if (c == "\\") {
          var t = KdlTokenizer(this.str, start: this.index + 1);
          var la = t.nextToken();
          if (la[0] == KdlToken.NEWLINE || la[0] == KdlToken.EOF) {
            this.index = t.index;
            _setContext(KdlTokenizerContext.whitespace);
            this.buffer = "${c}${la[1]}";
            continue;
          } else if (la[0] == KdlToken.WS) {
            var lan = t.nextToken();
            if (lan[0] == KdlToken.NEWLINE || lan[0] == KdlToken.EOF) {
              this.index = t.index;
              _setContext(KdlTokenizerContext.whitespace);
              this.buffer = "${c}${la[1]}";
              if (lan[0] == KdlToken.NEWLINE) {
                this.buffer += "\n";
              }
              continue;
            }
          }
          throw "Unexpected '\\'";
        } else if (EQUALS.contains(c)) {
          _setContext(KdlTokenizerContext.equals);
          this.buffer = c;
          this.index += 1;
        } else if (SYMBOLS.containsKey(c)) {
          this.index += 1;
          return [SYMBOLS[c], c];
        } else if (c == "\r") {
          var n = _charAt(this.index + 1);
          if (n == "\n") {
            this.index += 2;
            return [KdlToken.NEWLINE, "${c}${n}"];
          } else {
            this.index += 1;
            return [KdlToken.NEWLINE, c];
          }
        } else if (NEWLINES.contains(c)) {
          this.index += 1;
          return [KdlToken.NEWLINE, c];
        } else if (c == "/") {
          var n = _charAt(this.index + 1);
          if (n == '/') {
            if (inType || lastToken == KdlToken.RPAREN) throw "Unexpected '/'";
            _setContext(KdlTokenizerContext.singleLineComment);
            this.index += 2;
          } else if (n == '*') {
            _setContext(KdlTokenizerContext.multiLineComment);
            this.commentNesting = 1;
            this.index += 2;
          } else if (n == '-') {
            this.index += 2;
            return [KdlToken.SLASHDASH, '/-'];
          } else {
            throw "Unexpected character '${c}'";
          }
        } else if (WHITESPACE.contains(c)) {
          _setContext(KdlTokenizerContext.whitespace);
          this.buffer = c;
          this.index += 1;
        } else if (c == null) {
          if (this.done) {
            return [false, false];
          }
          this.done = true;
          return [KdlToken.EOF, ''];
        } else if (!NON_INITIAL_IDENTIFIER_CHARS.contains(c)) {
          _setContext(KdlTokenizerContext.ident);
          this.buffer = c;
          this.index += 1;
        } else if (c == '(') {
          this.inType = true;
          this.index += 1;
          return [KdlToken.LPAREN, c];
        } else if (c == ')') {
          this.inType = false;
          this.index += 1;
          return [KdlToken.RPAREN, c];
        } else {
          throw "Unexpected character '${c}'";
        }
      } else {
        switch(this.context) {
        case KdlTokenizerContext.ident:
          if (!NON_IDENTIFIER_CHARS.contains(c)) {
            this.index += 1;
            this.buffer += c;
            break;
          } else {
            if (['true', 'false', 'null', 'inf', '-inf', 'nan'].contains(this.buffer)) {
              throw "Identifier cannot be a literal";
            } else if (RegExp(r"^\.\d").hasMatch(this.buffer)) {
              throw "Identifier cannot look like an illegal float";
            } else {
              return [KdlToken.IDENT, this.buffer];
            }
          }
        case KdlTokenizerContext.keyword:
          if (c != null && RegExp(r"[a-z\-]").hasMatch(c)) {
            this.index += 1;
            this.buffer += c;
          } else {
            switch (this.buffer) {
            case '#true': return [KdlToken.TRUE, true];
            case '#false': return [KdlToken.FALSE, false];
            case '#null': return [KdlToken.NULL, null];
            case '#inf': return [KdlToken.DOUBLE, double.infinity];
            case '#-inf': return [KdlToken.DOUBLE, -double.infinity];
            case '#nan': return [KdlToken.DOUBLE, double.nan];
            default: throw "Unknown keyword ${this.buffer}";
            }
          }
        case KdlTokenizerContext.string:
        case KdlTokenizerContext.multiLineString:
          switch (c) {
          case '\\':
            this.buffer += c;
            this.buffer += _charAt(this.index + 1);
            this.index += 2;
            break;
          case '"':
            this.index += 1;
            var string = _convertEscapes(this.buffer);
            string = this.context == KdlTokenizerContext.multiLineString ? _unindent(string) : string;
            return [KdlToken.STRING, string];
          case '':
            throw "Unterminated string literal";
          default:
            this.buffer += c;
            this.index += 1;
            break;
          }
          break;
        case KdlTokenizerContext.rawstring:
        case KdlTokenizerContext.multiLineRawstring:
          if (c == null) {
            throw "Unterminated rawstring literal";
          }

          if (c == '"') {
            var h = 0;
            while (_charAt(this.index + 1 + h) == '#' && h < this.rawstringHashes) {
              h += 1;
            }
            if (h == this.rawstringHashes) {
              this.index += 1 + h;
              var string = this.context == KdlTokenizerContext.multiLineRawstring ? _unindent(this.buffer) : this.buffer;
              return [KdlToken.RAWSTRING, string];
            }
          }

          this.buffer += c;
          this.index += 1;
          break;
        case KdlTokenizerContext.decimal:
          if (c != null && RegExp(r"[0-9.\-+_eE]").hasMatch(c)) {
              this.index += 1;
              this.buffer += c;
          } else if (WHITESPACE.contains(c) || NEWLINES.contains(c) || c == null) {
            return _parseDecimal(this.buffer);
          } else {
            throw "Unexpected '$c'";
          }
          break;
        case KdlTokenizerContext.hexadecimal:
          if (c != null && RegExp(r"[0-9a-fA-F_]").hasMatch(c)) {
            this.index += 1;
            this.buffer += c;
          } else if (WHITESPACE.contains(c) || NEWLINES.contains(c) || c == null) {
            return _parseHexadecimal(this.buffer);
          } else {
            throw "Unexpected '$c'";
          }
          break;
        case KdlTokenizerContext.octal:
          if (c != null && RegExp(r"[0-7_]").hasMatch(c)) {
            this.index += 1;
            this.buffer += c;
          } else if (WHITESPACE.contains(c) || NEWLINES.contains(c) || c == null) {
            return _parseOctal(this.buffer);
          } else {
            throw "Unexpected '$c'";
          }
          break;
        case KdlTokenizerContext.binary:
          if (c != null && RegExp(r"[01_]").hasMatch(c)) {
            this.index += 1;
            this.buffer += c;
          } else if (WHITESPACE.contains(c) || NEWLINES.contains(c) || c == null) {
            return _parseBinary(this.buffer);
          } else {
            throw "Unexpected '$c'";
          }
          break;
        case KdlTokenizerContext.singleLineComment:
          if (NEWLINES.contains(c) || c == "\r") {
            _setContext(null);
            continue;
          } else if (c == null) {
            this.done = true;
            return [KdlToken.EOF, ''];
          } else {
            this.index += 1;
          }
          break;
        case KdlTokenizerContext.multiLineComment:
          var n = _charAt(this.index + 1);
          if (c == '/' && n == '*') {
            this.commentNesting += 1;
            this.index += 2;
          } else if (c == '*' && n == '/') {
            this.commentNesting -= 1;
            this.index += 2;
            if (this.commentNesting == 0) {
              _revertContext();
            }
          } else {
            this.index += 1;
          }
          break;
        case KdlTokenizerContext.whitespace:
          if (WHITESPACE.contains(c)) {
            this.index += 1;
            this.buffer += c;
          } else if (EQUALS.contains(c)) {
            _setContext(KdlTokenizerContext.equals);
            this.buffer += c;
            this.index += 1;
          } else if (c == "\\") {
            var t = KdlTokenizer(this.str, start: this.index + 1);
            var la = t.nextToken();
            if (la[0] == KdlToken.NEWLINE || la[0] == KdlToken.EOF) {
              this.index = t.index;
              this.buffer += "${c}${la[1]}";
              continue;
            } else if (la[0] == KdlToken.WS) {
              var lan = t.nextToken();
              if (lan[0] == KdlToken.NEWLINE || lan[0] == KdlToken.EOF) {
                this.index = t.index;
                this.buffer += "${c}${la[1]}";
                if (lan[0] == KdlToken.NEWLINE) {
                  this.buffer += "\n";
                }
                continue;
              }
            }
            throw "Unexpected '\\'";
          } else if (c == "/" && _charAt(this.index + 1) == '*') {
            _setContext(KdlTokenizerContext.multiLineComment);
            this.commentNesting = 1;
            this.index += 2;
          } else {
            return [KdlToken.WS, this.buffer];
          }
          break;
        case KdlTokenizerContext.equals:
          var t = KdlTokenizer(this.str, start: this.index);
          var la = t.nextToken();
          if (la[0] == KdlToken.WS) {
            this.buffer += la[1];
            this.index = t.index;
          }
          return [KdlToken.EQUALS, this.buffer];
        case null:
          throw "Unexpected null context";
        }
      }
    }
  }

  _charAt(int i) {
    if (i < 0 || i >= this.str.runes.length) {
      return null;
    }
    var char = String.fromCharCode(str.runes.elementAt(i));
    if (FORBIDDEN.contains(char)) {
      throw "Forbidden character: ${char}";
    }
    return char;
  }

  _revertContext() {
    this.context = this.previousContext;
    this.previousContext = null;
  }

  _integerContext(String n) {
    switch (n) {
      case 'b': return KdlTokenizerContext.binary;
      case 'o': return KdlTokenizerContext.octal;
      case 'x': return KdlTokenizerContext.hexadecimal;
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
      if (
        NON_INITIAL_IDENTIFIER_CHARS.contains(String.fromCharCode(s.runes.first)) ||
        s.runes.skip(1).any((c) => NON_IDENTIFIER_CHARS.contains(String.fromCharCode(c)))
      ) {
        throw e;
      }
      return [KdlToken.IDENT, s];
    }
  }

  _checkFloat(String s) {
    if (!RegExp(r"^[+-]?[0-9][0-9_]*(\.[0-9][0-9_]*)?([eE][+-]?[0-9][0-9_]*)?$").hasMatch(s)) {
      throw "Invalid float: ${s}";
    }
  }
  
  _checkInt(String s) {
    if (!RegExp(r"^[+-]?[0-9][0-9_]*$").hasMatch(s)) {
      throw "Invalid integer: ${s}";
    }
  }
  
  _parseHexadecimal(String s) {
    if (!RegExp(r"^[+-]?[0-9a-fA-F][0-9a-fA-F_]*$").hasMatch(s)) throw "Invalid hexadecimal: ${s}";
    return [KdlToken.INTEGER, _parseInteger(_munchUnderscores(s),  16)];
  }
  
  _parseOctal(String s) {
    if (!RegExp(r"^[+-]?[0-7][0-7_]*$").hasMatch(s)) throw "Invalid octal: ${s}";
    return [KdlToken.INTEGER, _parseInteger(_munchUnderscores(s), 8)];
  }
  
  _parseBinary(String s) {
    if (!RegExp(r"^[+-]?[01][01_]*$").hasMatch(s)) throw "Invalid binary: ${s}";
    return [KdlToken.INTEGER, _parseInteger(_munchUnderscores(s), 2)];
  }

  _munchUnderscores(String s) {
    return s.replaceAll('_', '');
  }

  _convertEscapes(String string) {
    return string.replaceAllMapped(RegExp(r"\\(\s+|[^u])"), (match) {
      var m = match.group(0);
      switch (m) {
        case r'\n': return "\n";
        case r'\r': return "\r";
        case r'\t': return "\t";
        case r'\\': return "\\";
        case r'\"': return "\"";
        case r'\b': return "\b";
        case r'\f': return "\f";
        case "\\\n": return "";
        case r'\s': return ' ';
        default: 
          if (m != null && RegExp(r"\\\s+").hasMatch(m)) return '';
          throw "Unexpected escape '${match.group(0)}'";
      }
    }).replaceAllMapped(RegExp(r"\\u\{[0-9a-fA-F]{1,6}\}"), (match) {
      String m = match.group(0) ?? '';
      int i = int.parse(m.substring(3, m.length - 1), radix: 16);
      if (i < 0 || i > 0x10FFFF) {
        throw "Invalid code point ${m}";
      }
      return String.fromCharCode(i);
    });
  }

  _parseInteger(String string, int radix) {
    try {
      return int.parse(string, radix: radix);
    } catch (FormatException) {
      return BigInt.parse(string, radix: radix);
    }
  }

  _unindent(String string) {
    var [...lines, indent] = string.split("\n");

    if (!indent.isEmpty) {
      if (indent.split('').any((c) => !WHITESPACE.contains(c))) {
        throw "Invalid multiline string final line";
      }
      if (lines.any((line) => !line.startsWith(indent))) {
        throw "Invalid multiline string indentation";
      }
    }

    return lines.map((line) => line.substring(indent.length)).join("\n");
  }
}
