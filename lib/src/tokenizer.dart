import 'dart:ffi';

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
  LPAREN,
  RPAREN,
  EQUALS,
  SEMICOLON,
  EOF,
  SLASHDASH,
}


class KdlTokenizer {
  static const SYMBOLS = {
    '{': KdlToken.LPAREN,
    '}': KdlToken.RPAREN,
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

  static var NON_IDENTIFIER_CHARS = [
    null,
    ...WHITESPACE,
    ...NEWLINES,
    ...SYMBOLS.keys,
    "\\", "<", ">", "[", "]", '"', ",",
    List.generate(0x20, (index) => String.fromCharCode(index))];
  static var NON_INITIAL_IDENTIFIER_CHARS = [
    ...NON_IDENTIFIER_CHARS,
    List.generate(10, (index) => index.toString())
  ];

  String str;
  KdlTokenizerContext context = null;
  int rawstringHashes = null;
  int index = 0;
  String buffer = "";
  bool done = false;
  KdlTokenizerContext previousContext = null;
  int commentNesting = 0;
  
  KdlTokenizer(String str, { int start: 0 }) {
    this.str = str;
    this.index = start;
  }

  setContext(KdlTokenizerContext ctx) {
    this.previousContext = this.context;
    this.context = ctx;
  }

  nextToken() {
    this.context = null;
    this.previousContext = null;
    while (true) {
      var c = charAt(this.index);
      if (this.context == null) {
        if (c == '"') {
          setContext(KdlTokenizerContext.string);
          this.buffer = '';
          this.index += 1;
        } else if (c == 'r') {
          if (charAt(this.index + 1) == '"') {
            setContext(KdlTokenizerContext.rawstring);
            this.index += 2;
            this.rawstringHashes = 0;
            this.buffer = '';
            continue;
          } else if (charAt(this.index + 1) == '#') {
            var i = this.index + 1;
            this.rawstringHashes = 0;
            while (charAt(i) == '#') {
              this.rawstringHashes += 1;
              i += 1;
            }
            if (charAt(i) == '"') {
              setContext(KdlTokenizerContext.rawstring);
              this.index = i + 1;
              this.buffer = '';
              continue;
            }
          }
          setContext(KdlTokenizerContext.ident);
          this.buffer = c;
          this.index += 1;
        } else if (c != null && RegExp(r"[0-9\-+]").hasMatch(c)) {
          var n = charAt(this.index + 1);
          if (c == '0' && RegExp("[box]").hasMatch(n)) {
            this.index += 2;
            this.buffer = '';
            switch (n) {
              case 'b': setContext(KdlTokenizerContext.binary); break;
              case 'o': setContext(KdlTokenizerContext.octal); break;
              case 'x': setContext(KdlTokenizerContext.hexadecimal); break;
            }
          } else {
            setContext(KdlTokenizerContext.decimal);
            this.index += 1;
            this.buffer = c;
          }
        } else if (c == "\\") {
          var t = KdlTokenizer(this.str, start: this.index + 1);
          var la = t.nextToken()[0];
          if (la == KdlToken.NEWLINE) {
            this.index = t.index;
          } else if (la == KdlToken.WS && t.nextToken()[0] == KdlToken.NEWLINE) {
            this.index = t.index;
          } else {
            throw "Unexpected '\\'";
          }
        } else if (SYMBOLS.containsKey(c)) {
          this.index += 1;
          return [SYMBOLS[c], c];
        } else if (c == "\r") {
          var n = charAt(this.index + 1);
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
          var n = charAt(this.index + 1);
          if (n == '/') {
            setContext(KdlTokenizerContext.singleLineComment);
            this.index += 2;
          } else if (n == '*') {
            setContext(KdlTokenizerContext.multiLineComment);
            this.commentNesting = 1;
            this.index += 2;
          } else if (n == '-') {
            this.index += 2;
            return [KdlToken.SLASHDASH, '/-'];
          } else {
            setContext(KdlTokenizerContext.ident);
            this.buffer = c;
            this.index += 1;
          }
        } else if (WHITESPACE.contains(c)) {
          setContext(KdlTokenizerContext.whitespace);
          this.buffer = c;
          this.index += 1;
        } else if (c == null) {
          if (this.done) {
            return [false, false];
          }
          this.done = true;
          return [KdlToken.EOF, ''];
        } else if (!NON_INITIAL_IDENTIFIER_CHARS.contains(c)) {
          setContext(KdlTokenizerContext.ident);
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
          break;
        case KdlTokenizerContext.string:
          switch (c) {
          case '\\':
            this.buffer += c;
            this.buffer += charAt(this.index + 1);
            this.index += 2;
            break;
          case '"':
            this.index += 1;
            return [KdlToken.STRING, convertEscapes(this.buffer)];
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
            while (charAt(this.index + 1 + h) == '#' && h < this.rawstringHashes) {
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
          } else {
            return parseDecimal(this.buffer);
          }
          break;
        case KdlTokenizerContext.hexadecimal:
          if (c != null && RegExp(r"[0-9a-fA-F_]").hasMatch(c)) {
            this.index += 1;
            this.buffer += c;
          } else {
            return parseHexadecimal(this.buffer);
          }
          break;
        case KdlTokenizerContext.octal:
          if (c != null && RegExp(r"[0-7_]").hasMatch(c)) {
            this.index += 1;
            this.buffer += c;
          } else {
            return parseOctal(this.buffer);
          }
          break;
        case KdlTokenizerContext.binary:
          if (c != null && RegExp(r"[01_]").hasMatch(c)) {
            this.index += 1;
            this.buffer += c;
          } else {
            return parseBinary(this.buffer);
          }
          break;
        case KdlTokenizerContext.singleLineComment:
          if (NEWLINES.contains(c) || c == "\r") {
            setContext(null);
            continue;
          } else if (c == null) {
            this.done = true;
            return [KdlToken.EOF, ''];
          } else {
            this.index += 1;
          }
          break;
        case KdlTokenizerContext.multiLineComment:
          var n = charAt(this.index + 1);
          if (c == '/' && n == '*') {
            this.commentNesting += 1;
            this.index += 2;
          } else if (c == '*' && n == '/') {
            this.commentNesting -= 1;
            this.index += 2;
            if (this.commentNesting == 0) {
              revertContext();
            }
          } else {
            this.index += 1;
          }
          break;
        case KdlTokenizerContext.whitespace:
          if (WHITESPACE.contains(c)) {
            this.index += 1;
            this.buffer += c;
          } else if (c == "\\") {
            var t = KdlTokenizer(this.str, start: this.index + 1);
            var la = t.nextToken()[0];
            KdlToken lan;
            if (la == KdlToken.NEWLINE) {
              this.index = t.index;
            } else if (la == KdlToken.WS && (lan = t.nextToken()[0]) == KdlToken.NEWLINE) {
              this.index = t.index;
            } else {
              throw "Unexpected '\\'";
            }
          } else if (c == "/" && charAt(this.index + 1) == '*') {
            setContext(KdlTokenizerContext.multiLineComment);
            this.commentNesting = 1;
            this.index += 2;
          } else {
            return [KdlToken.WS, this.buffer];
          }
        }
      }
    }
  }

  charAt(int i) {
    if (i < 0 || i >= this.str.length) {
      return null;
    }
    return this.str[i];
  }

  revertContext() {
    this.context = this.previousContext;
    this.previousContext = null;
  }

  parseDecimal(String s) {
    if (RegExp("[.eE]").hasMatch(s)) {
      return [KdlToken.FLOAT, double.parse(munchUnderscores(s))];
    }
    return [KdlToken.INTEGER, int.parse(munchUnderscores(s), radix: 10)];
  }
  
  parseHexadecimal(String s) {
    return [KdlToken.INTEGER, int.parse(munchUnderscores(s), radix: 16)];
  }
  
  parseOctal(String s) {
    [KdlToken.INTEGER, int.parse(munchUnderscores(s), radix: 8)];
  }
  
  parseBinary(String s) {
    [KdlToken.INTEGER, int.parse(munchUnderscores(s), radix: 2)];
  }

  munchUnderscores(String s) {
    return s.replaceAll('_', '');
  }

  convertEscapes(String string) {
    return string.replaceAllMapped(RegExp(r"\\[^u]"), (match) {
      switch (match.group(0)) {
        case r'\n': return "\n";
        case r'\r': return "\r";
        case r'\t': return "\t";
        case r'\\': return "\\";
        case r'\"': return "\"";
        case r'\b': return "\b";
        case r'\f': return "\f";
        default: throw "Unexpectec escape '${match.group(0)}'";
      }
    }).replaceAllMapped(RegExp("r\\u\{[0-9a-fA-F]{0,6}\}"), (match) {
      var m = match.group(0);
      var i = int.parse(m.substring(3, m.length - 2), radix: 16);
      if (i < 0 || i > 0x10FFFF) {
        throw "Invalid code point ${m}";
      }
      return String.fromCharCode(i);
    });
  }
}
