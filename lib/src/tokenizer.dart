import 'dart:collection';
import 'package:big_decimal/big_decimal.dart';

enum KdlTokenizerContext {
  ident,
  string,
  rawstring,
  binary,
  octal,
  hexadecimal,
  decimal,
  singleLineComment,
  multiLineComment,
  whitespace,
}

enum KdlToken { 
  IDENT,
  STRING,
  RAWSTRING,
  INTEGER,
  FLOAT,
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
  ESCLINE,
}


class KdlTokenizer {
  static const SYMBOLS = {
    '(': KdlToken.LPAREN,
    ')': KdlToken.RPAREN,
    '{': KdlToken.LBRACE,
    '}': KdlToken.RBRACE,
    '=': KdlToken.EQUALS,
    '＝': KdlToken.EQUALS,
    ';': KdlToken.SEMICOLON
  };

  static const WHITESPACE = [
    "\u0009", "\u0020", "\u00A0", "\u1680",
    "\u2000", "\u2001", "\u2002", "\u2003",
    "\u2004", "\u2005", "\u2006", "\u2007",
    "\u2008", "\u2009", "\u200A", "\u202F",
    "\u205F", "\u3000" 
  ];

  static const NEWLINES = ["\u000A", "\u0085", "\u000C", "\u2028", "\u2029"];

  static final NON_IDENTIFIER_CHARS = [
    null,
    ...WHITESPACE,
    ...NEWLINES,
    ...SYMBOLS.keys,
    "\r", "\\", "<", ">", "[", "]", '"', ",", "/",
    List.generate(0x20, (index) => String.fromCharCode(index))];
  static final NON_INITIAL_IDENTIFIER_CHARS = [
    ...NON_IDENTIFIER_CHARS,
    List.generate(10, (index) => index.toString())
  ];

  String str = '';
  KdlTokenizerContext? context = null;
  int rawstringHashes = -1;
  int index = 0;
  String buffer = "";
  bool done = false;
  KdlTokenizerContext? previousContext = null;
  int commentNesting = 0;
  Queue peekedTokens = Queue();
  bool inType = false;
  KdlToken? lastToken = null;

  KdlTokenizer(String str, { int start = 0 }) {
    this.str = str;
    this.index = start;
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
          _setContext(KdlTokenizerContext.string);
          this.buffer = '';
          this.index += 1;
        } else if (c == 'r') {
          if (_charAt(this.index + 1) == '"') {
            _setContext(KdlTokenizerContext.rawstring);
            this.index += 2;
            this.rawstringHashes = 0;
            this.buffer = '';
            continue;
          } else if (_charAt(this.index + 1) == '#') {
            var i = this.index + 1;
            this.rawstringHashes = 0;
            while (_charAt(i) == '#') {
              this.rawstringHashes += 1;
              i += 1;
            }
            if (_charAt(i) == '"') {
              _setContext(KdlTokenizerContext.rawstring);
              this.index = i + 1;
              this.buffer = '';
              continue;
            }
          }
          _setContext(KdlTokenizerContext.ident);
          this.buffer = c;
          this.index += 1;
        } else if (c != null && RegExp(r"[0-9\-+]").hasMatch(c)) {
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
            return [KdlToken.ESCLINE, "\\${la[1]}"];
          } else if (la[0] == KdlToken.WS) {
            var lan = t.nextToken();
            if (lan[0] == KdlToken.NEWLINE || lan[0] == KdlToken.EOF) {
              this.index = t.index;
              return [KdlToken.ESCLINE, "\\${la[1]}${lan[1]}"];
            }
          }
          throw "Unexpected '\\'";
        } else if (SYMBOLS.containsKey(c)) {
          if (c == '(') inType = true;
          if (c == ')') inType = false;
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
            if (inType || lastToken == KdlToken.RPAREN) throw "Unexpected '/'";
            _setContext(KdlTokenizerContext.multiLineComment);
            this.commentNesting = 1;
            this.index += 2;
          } else if (n == '-') {
            this.index += 2;
            return [KdlToken.SLASHDASH, '/-'];
          } else {
            _setContext(KdlTokenizerContext.ident);
            this.buffer = c;
            this.index += 1;
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
            switch (this.buffer) {
            case 'true': return [KdlToken.TRUE, true];
            case 'false': return [KdlToken.FALSE, false];
            case 'null': return [KdlToken.NULL, null];
            default: return [KdlToken.IDENT, this.buffer];
            }
          }
        case KdlTokenizerContext.string:
          switch (c) {
          case '\\':
            this.buffer += c;
            this.buffer += _charAt(this.index + 1);
            this.index += 2;
            break;
          case '"':
            this.index += 1;
            return [KdlToken.STRING, _convertEscapes(this.buffer)];
          case '':
            throw "Unterminated string literal";
          default:
            this.buffer += c;
            this.index += 1;
            break;
          }
          break;
        case KdlTokenizerContext.rawstring:
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
              return [KdlToken.RAWSTRING, this.buffer];
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
          } else if (c == "/" && _charAt(this.index + 1) == '*') {
            _setContext(KdlTokenizerContext.multiLineComment);
            this.commentNesting = 1;
            this.index += 2;
          } else {
            return [KdlToken.WS, this.buffer];
          }
          break;
        case null:
          throw "Unexpected null context";
        }
      }
    }
  }

  _charAt(int i) {
    if (i < 0 || i >= this.str.length) {
      return null;
    }
    return this.str[i];
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
    if (RegExp("[.eE]").hasMatch(s)) {
      _checkFloat(s);
      return [KdlToken.FLOAT, BigDecimal.parse(_munchUnderscores(s))];
    }
    _checkInt(s);
    return [KdlToken.INTEGER, _parseInteger(_munchUnderscores(s), 10)];
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
    return string.replaceAllMapped(RegExp(r"\\[^u]"), (match) {
      switch (match.group(0)) {
        case r'\n': return "\n";
        case r'\r': return "\r";
        case r'\t': return "\t";
        case r'\\': return "\\";
        case r'\"': return "\"";
        case r'\b': return "\b";
        case r'\f': return "\f";
        case r'\/': return "/";
        default: throw "Unexpected escape '${match.group(0)}'";
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
}
