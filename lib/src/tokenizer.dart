import 'dart:collection';
import 'package:big_decimal/big_decimal.dart';
import 'package:kdl/src/exception.dart';

enum _KdlTokenizerContext {
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

/// KDL Token types, aka Terminals
enum KdlTerm {
  /// Identifier
  ident,

  /// String
  string,

  /// Rawstring
  rawstring,

  /// Integer
  integer,

  /// Floating-point literal
  decimal,

  /// Floating-point special values, e.g. `#inf`
  double,

  /// #true
  trueKeyword,

  /// #false
  falseKeyword,

  /// #null
  nullKeyword,

  /// Whitespace
  whitespace,

  /// Newline
  newline,

  /// Left brace `{`
  lbrace,

  /// Right brace `}`
  rbrace,

  /// Left parenthesis `(`
  lparen,

  /// Right parenthesis `)`
  rparen,

  /// Equals `=`
  equals,

  /// Semi-colon `;`
  semicolon,

  /// End-of-file
  eof,

  /// Slashdash `/-`
  slashdash,
}

List _charRange(int from, int to) =>
    List.generate(to - from + 1, (i) => String.fromCharCode(i + from));

String _debom(String str) {
  if (str.startsWith("\uFEFF")) {
    return str.substring(1);
  }

  return str;
}

/// Represents a terminal token
class KdlToken {
  /// The type of the token
  KdlTerm type;

  /// The parsed value resulting from the token
  dynamic value;

  /// Starting line number where the token was found
  int? line;

  /// Starting column number where the token was found
  int? column;

  /// Construct a new token
  KdlToken(this.type, this.value, [this.line, this.column]);

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

  @override
  String toString() {
    return "KdlToken($type, ${value.toString()}, $line, $column)";
  }

  @override
  int get hashCode => [type, value, line, column].hashCode;
}

/// Turns strings into a list of tokens
class KdlTokenizer {
  /// Symbol characters
  static final symbols = {
    '{': KdlTerm.lbrace,
    '}': KdlTerm.rbrace,
    ';': KdlTerm.semicolon,
    '=': KdlTerm.equals
  };

  /// Whitespace characters
  static const whitespace = [
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
  static final _ws = "[${RegExp.escape(whitespace.join())}]";
  static final _wsStar = RegExp("^$_ws*\$");

  /// Newline characters
  static const newlines = [
    "\u000A",
    "\u0085",
    "\u000B",
    "\u000C",
    "\u2028",
    "\u2029"
  ];
  static final _newlinesPattern =
      RegExp("${newlines.map(RegExp.escape).join('|')}|\\r\\n?");

  static final _nonIdentifierChars = [
    null,
    ...whitespace,
    ...newlines,
    ...symbols.keys,
    "\r",
    "\\",
    "[",
    "]",
    "(",
    ")",
    '"',
    "/",
    "#",
    ..._charRange(0x0000, 0x0020),
  ];
  static final _nonInitialIdentifierChars = [
    ..._nonIdentifierChars,
    ...List.generate(10, (index) => index.toString()),
  ];

  static final _forbidden = [
    ..._charRange(0x0000, 0x0008),
    ..._charRange(0x000E, 0x001F),
    "\u007F",
    ..._charRange(0x200E, 0x200F),
    ..._charRange(0x202A, 0x202E),
    ..._charRange(0x2066, 0x2069),
    "\uFEFF"
  ];

  String _str = '';
  _KdlTokenizerContext? _ctx;
  int _rawstringHashes = -1;
  int _index = 0;
  final int _start;
  String _buffer = "";
  bool _done = false;
  _KdlTokenizerContext? _previousContext;
  int _commentNesting = 0;
  final Queue _peekedTokens = Queue();
  bool _inType = false;
  KdlToken? _lastToken;
  int _line = 1;
  int _column = 1;
  int _lineAtStart = 1;
  int _columnAtStart = 1;

  /// Create a new KDL Tokenizer
  KdlTokenizer(String str, {int start = 0}) : _start = start {
    _str = _debom(str);
    _index = _start;
  }

  static final _versionPattern =
      RegExp("\\/-$_ws*kdl-version$_ws+(\\d+)$_ws*${_newlinesPattern.pattern}");

  /// Reads the version of the document if there is one, e.g. `/- kdl-version 2`
  versionDirective() {
    var match = _versionPattern.matchAsPrefix(_str);
    if (match == null) return null;
    var m = match.group(1);
    if (m == null) return null;
    return int.parse(m);
  }

  /// Consumes the entire string and returns all tokens
  allTokens() {
    List a = [];
    while (!_done) {
      a.add(nextToken());
    }
    return a;
  }

  set _context(_KdlTokenizerContext? ctx) {
    _previousContext = _ctx;
    _ctx = ctx;
  }

  _KdlTokenizerContext? get _context => _ctx;

  /// Read the next token without consuming it
  KdlToken peekToken() {
    if (_peekedTokens.isEmpty) {
      _peekedTokens.add(_readToken());
    }
    return _peekedTokens.first;
  }

  /// Read two tokens ahead without consuming
  KdlToken peekTokenAfterNext() {
    if (_peekedTokens.isEmpty) {
      _peekedTokens.add(_readToken());
      _peekedTokens.add(_readToken());
    } else if (_peekedTokens.length == 1) {
      _peekedTokens.add(_readToken());
    }
    return _peekedTokens.elementAt(1);
  }

  /// Consume the next token and return it
  KdlToken nextToken() {
    if (_peekedTokens.isNotEmpty) {
      return _peekedTokens.removeFirst();
    } else {
      return _readToken();
    }
  }

  KdlToken _readToken() {
    _context = null;
    _previousContext = null;
    _lineAtStart = _line;
    _columnAtStart = _column;
    while (true) {
      var c = _char(_index);
      if (_context == null) {
        if (c == null) {
          if (_done) {
            return _token(KdlTerm.eof, null);
          }
          _done = true;
          return _token(KdlTerm.eof, '');
        } else if (c == '"') {
          if (_char(_index + 1) == '"' && _char(_index + 2) == '"') {
            String nl = _expectNewline(_index + 3);
            _context = _KdlTokenizerContext.multiLineString;
            _buffer = '';
            _traverse(3 + nl.runes.length);
          } else {
            _context = _KdlTokenizerContext.string;
            _buffer = '';
            _traverse(1);
          }
        } else if (c == '#') {
          if (_char(_index + 1) == '"') {
            if (_char(_index + 2) == '"' && _char(_index + 3) == '"') {
              String nl = _expectNewline(_index + 4);
              _context = _KdlTokenizerContext.multiLineRawstring;
              _rawstringHashes = 1;
              _buffer = '';
              _traverse(4 + nl.runes.length);
              continue;
            } else {
              _context = _KdlTokenizerContext.rawstring;
              _traverse(2);
              _rawstringHashes = 1;
              _buffer = '';
              continue;
            }
          } else if (_char(_index + 1) == '#') {
            var i = _index + 1;
            _rawstringHashes = 1;
            while (_char(i) == '#') {
              _rawstringHashes += 1;
              i += 1;
            }
            if (_char(i) == '"') {
              if (_char(i + 1) == '"' && _char(i + 2) == '"') {
                String nl = _expectNewline(i + 3);
                _context = _KdlTokenizerContext.multiLineRawstring;
                _buffer = '';
                _traverse(_rawstringHashes + 3 + nl.runes.length);
                continue;
              } else {
                _context = _KdlTokenizerContext.rawstring;
                _traverse(_rawstringHashes + 1);
                _buffer = '';
                continue;
              }
            }
          }
          _context = _KdlTokenizerContext.keyword;
          _buffer = c;
          _traverse(1);
        } else if (c == '-') {
          var n = _char(_index + 1);
          var n2 = _char(_index + 2);
          if (n != null && RegExp(r"[0-9]").hasMatch(n)) {
            if (n == '0' && n2 != null && RegExp(r"[box]").hasMatch(n2)) {
              _context = _integerContext(n2);
              _traverse(2);
            } else {
              _context = _KdlTokenizerContext.decimal;
            }
          } else {
            _context = _KdlTokenizerContext.ident;
          }
          _buffer = c;
          _traverse(1);
        } else if (RegExp(r"[0-9+]").hasMatch(c)) {
          var n = _char(_index + 1);
          var n2 = _char(_index + 2);
          if (c == '0' && n != null && RegExp("[box]").hasMatch(n)) {
            _buffer = '';
            _context = _integerContext(n);
            _traverse(2);
          } else if (c == '+' && n == '0' && RegExp("[box]").hasMatch(n2)) {
            _buffer = c;
            _context = _integerContext(n2);
            _traverse(3);
          } else {
            _buffer = c;
            _context = _KdlTokenizerContext.decimal;
            _traverse(1);
          }
        } else if (c == "\\") {
          var t = KdlTokenizer(_str, start: _index + 1);
          var la = t.nextToken();
          if (la.type == KdlTerm.newline || la.type == KdlTerm.eof) {
            _buffer = "$c${la.value}";
            _context = _KdlTokenizerContext.whitespace;
            _traverseTo(t._index);
            continue;
          } else if (la.type == KdlTerm.whitespace) {
            var lan = t.nextToken();
            if (lan.type == KdlTerm.newline || lan.type == KdlTerm.eof) {
              _buffer = "$c${la.value}";
              if (lan.type == KdlTerm.newline) _buffer += "\n";
              _context = _KdlTokenizerContext.whitespace;
              _traverseTo(t._index);
              continue;
            }
          }
          _fail("Unexpected '\\'");
        } else if (c == '=') {
          _buffer = c;
          _context = _KdlTokenizerContext.equals;
          _traverse(1);
        } else if (symbols.containsKey(c)) {
          _traverse(1);
          return KdlToken(symbols[c]!, c);
        } else if (c == "\r" || newlines.contains(c)) {
          String nl = _expectNewline(_index);
          _traverse(nl.runes.length);
          return _token(KdlTerm.newline, nl);
        } else if (c == "/") {
          var n = _char(_index + 1);
          if (n == '/') {
            if (_inType || _lastToken?.type == KdlTerm.rparen) {
              _fail("Unexpected '/'");
            }
            _context = _KdlTokenizerContext.singleLineComment;
            _traverse(2);
          } else if (n == '*') {
            _commentNesting = 1;
            _context = _KdlTokenizerContext.multiLineComment;
            _traverse(2);
          } else if (n == '-') {
            _traverse(2);
            return _token(KdlTerm.slashdash, '/-');
          } else {
            _fail("Unexpected character '$c'");
          }
        } else if (whitespace.contains(c)) {
          _buffer = c;
          _context = _KdlTokenizerContext.whitespace;
          _traverse(1);
        } else if (!_nonInitialIdentifierChars.contains(c)) {
          _buffer = c;
          _context = _KdlTokenizerContext.ident;
          _traverse(1);
        } else if (c == '(') {
          _inType = true;
          _traverse(1);
          return _token(KdlTerm.lparen, c);
        } else if (c == ')') {
          _inType = false;
          _traverse(1);
          return _token(KdlTerm.rparen, c);
        } else {
          _fail("Unexpected character '$c'");
        }
      } else {
        switch (_context) {
          case _KdlTokenizerContext.ident:
            if (!_nonIdentifierChars.contains(c)) {
              _buffer += c;
              _traverse(1);
              break;
            } else {
              if (['true', 'false', 'null', 'inf', '-inf', 'nan']
                  .contains(_buffer)) {
                _fail("Identifier cannot be a literal");
              } else if (RegExp(r"^\.\d").hasMatch(_buffer)) {
                _fail("Identifier cannot look like an illegal float");
              } else {
                return _token(KdlTerm.ident, _buffer);
              }
            }
          case _KdlTokenizerContext.keyword:
            if (c != null && RegExp(r"[a-z\-]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
              break;
            } else {
              switch (_buffer) {
                case '#true':
                  return _token(KdlTerm.trueKeyword, true);
                case '#false':
                  return _token(KdlTerm.falseKeyword, false);
                case '#null':
                  return _token(KdlTerm.nullKeyword, null);
                case '#inf':
                  return _token(KdlTerm.double, double.infinity);
                case '#-inf':
                  return _token(KdlTerm.double, -double.infinity);
                case '#nan':
                  return _token(KdlTerm.double, double.nan);
                default:
                  _fail("Unknown keyword $_buffer");
              }
            }
          case _KdlTokenizerContext.string:
            switch (c) {
              case '\\':
                _buffer += c;
                var c2 = _char(_index + 1);
                _buffer += c2;
                if (newlines.contains(c2)) {
                  var i = 2;
                  while (newlines.contains(c2 = _char(_index + i))) {
                    _buffer += c2;
                    i += 1;
                  }
                  _traverse(i);
                } else {
                  _traverse(2);
                }
                break;
              case '"':
                _traverse(1);
                return _token(KdlTerm.string, _unescape(_buffer));
              case '':
              case null:
                _fail("Unterminated string literal");
              default:
                if (newlines.contains(c)) {
                  _fail("Unexpected NEWLINE in single-line string");
                }
                _buffer += c;
                _traverse(1);
                break;
            }
            break;
          case _KdlTokenizerContext.multiLineString:
            switch (c) {
              case '\\':
                _buffer += c;
                _buffer += _char(_index + 1);
                _traverse(2);
                break;
              case '"':
                if (_char(_index + 1) == '"' && _char(_index + 2) == '"') {
                  _traverse(3);
                  return _token(KdlTerm.string,
                      _unescapeNonWs(_dedent(_unescapeWs(_buffer))));
                }
                _buffer += c;
                _traverse(1);
                break;
              case null:
                _fail("Unterminated multi-line string literal");
              default:
                _buffer += c;
                _traverse(1);
                break;
            }
            break;
          case _KdlTokenizerContext.rawstring:
            if (c == null) {
              _fail("Unterminated rawstring literal");
            }

            if (c == '"') {
              var h = 0;
              while (_char(_index + 1 + h) == '#' && h < _rawstringHashes) {
                h += 1;
              }
              if (h == _rawstringHashes) {
                _traverse(1 + h);
                return _token(KdlTerm.rawstring, _buffer);
              }
            } else if (newlines.contains(c)) {
              _fail("Unexpected NEWLINE in single-line string");
            }

            _buffer += c;
            _traverse(1);
            break;
          case _KdlTokenizerContext.multiLineRawstring:
            if (c == null) {
              _fail("Unterminated multi-line rawstring literal");
            }

            if (c == '"' &&
                _char(_index + 1) == '"' &&
                _char(_index + 2) == '"' &&
                _char(_index + 3) == '#') {
              var h = 1;
              while (_char(_index + 3 + h) == '#' && h < _rawstringHashes) {
                h += 1;
              }
              if (h == _rawstringHashes) {
                _traverse(3 + h);
                return _token(KdlTerm.rawstring, _dedent(_buffer));
              }
            }

            _buffer += c;
            _traverse(1);
            break;
          case _KdlTokenizerContext.decimal:
            if (c != null && RegExp(r"[0-9.\-+_eE]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
            } else if (whitespace.contains(c) ||
                newlines.contains(c) ||
                c == null) {
              return _parseDecimal(_buffer);
            } else {
              _fail("Unexpected '$c'");
            }
            break;
          case _KdlTokenizerContext.hexadecimal:
            if (c != null && RegExp(r"[0-9a-fA-F_]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
            } else if (whitespace.contains(c) ||
                newlines.contains(c) ||
                c == null) {
              return _parseHexadecimal(_buffer);
            } else {
              _fail("Unexpected '$c'");
            }
            break;
          case _KdlTokenizerContext.octal:
            if (c != null && RegExp(r"[0-7_]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
            } else if (whitespace.contains(c) ||
                newlines.contains(c) ||
                c == null) {
              return _parseOctal(_buffer);
            } else {
              _fail("Unexpected '$c'");
            }
            break;
          case _KdlTokenizerContext.binary:
            if (c != null && RegExp(r"[01_]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
            } else if (whitespace.contains(c) ||
                newlines.contains(c) ||
                c == null) {
              return _parseBinary(_buffer);
            } else {
              _fail("Unexpected '$c'");
            }
            break;
          case _KdlTokenizerContext.singleLineComment:
            if (newlines.contains(c) || c == "\r") {
              _context = null;
              _columnAtStart = _column;
              continue;
            } else if (c == null) {
              _done = true;
              return _token(KdlTerm.eof, '');
            } else {
              _traverse(1);
            }
            break;
          case _KdlTokenizerContext.multiLineComment:
            var n = _char(_index + 1);
            if (c == '/' && n == '*') {
              _commentNesting += 1;
              _traverse(2);
            } else if (c == '*' && n == '/') {
              _commentNesting -= 1;
              _traverse(2);
              if (_commentNesting == 0) {
                _revertContext();
              }
            } else {
              _traverse(1);
            }
            break;
          case _KdlTokenizerContext.whitespace:
            if (whitespace.contains(c)) {
              _buffer += c;
              _traverse(1);
            } else if (c == '=') {
              _buffer += c;
              _context = _KdlTokenizerContext.equals;
              _traverse(1);
            } else if (c == "\\") {
              var t = KdlTokenizer(_str, start: _index + 1);
              var la = t.nextToken();
              if (la.type == KdlTerm.newline || la.type == KdlTerm.eof) {
                _buffer += "$c${la.value}";
                _traverseTo(t._index);
                continue;
              } else if (la.type == KdlTerm.whitespace) {
                var lan = t.nextToken();
                if (lan.type == KdlTerm.newline || lan.type == KdlTerm.eof) {
                  _buffer += "$c${la.value}";
                  if (lan.type == KdlTerm.newline) _buffer += "\n";
                  _traverseTo(t._index);
                  continue;
                }
              }
              _fail("Unexpected '\\'");
            } else if (c == "/" && _char(_index + 1) == '*') {
              _commentNesting = 1;
              _context = _KdlTokenizerContext.multiLineComment;
              _traverse(2);
            } else {
              return _token(KdlTerm.whitespace, _buffer);
            }
            break;
          case _KdlTokenizerContext.equals:
            var t = KdlTokenizer(_str, start: _index);
            var la = t.nextToken();
            if (la.type == KdlTerm.whitespace) {
              _buffer += la.value;
              _traverseTo(t._index);
            }
            return _token(KdlTerm.equals, _buffer);
          case null:
            _fail("Unexpected null context");
        }
      }
    }
  }

  _char(int i) {
    if (i < 0 || i >= _str.runes.length) {
      return null;
    }
    var char = String.fromCharCode(_str.runes.elementAt(i));
    if (_forbidden.contains(char)) {
      _fail("Forbidden character: $char");
    }
    return char;
  }

  KdlToken _token(KdlTerm type, value) {
    return _lastToken = KdlToken(type, value, _lineAtStart, _columnAtStart);
  }

  void _traverse([int n = 1]) {
    for (int i = 0; i < n; i++) {
      var c = _char(_index + i);
      if (c == "\r") {
        _column = 1;
      } else if (newlines.contains(c)) {
        _line += 1;
        _column = 1;
      } else {
        _column += 1;
      }
    }
    _index += n;
  }

  void _traverseTo(i) {
    _traverse(i - _index);
  }

  void _fail(message) {
    throw KdlParseException(message, _line, _column);
  }

  void _revertContext() {
    _ctx = _previousContext;
    _previousContext = null;
  }

  String _expectNewline(int i) {
    var c = _char(i);
    if (c == "\r") {
      var n = _char(i + 1);
      if (n == "\n") {
        return "$c$n";
      }
    } else if (!newlines.contains(c)) {
      _fail("Expected NEWLINE, found '$c'");
    }
    return c;
  }

  _integerContext(String n) {
    switch (n) {
      case 'b':
        return _KdlTokenizerContext.binary;
      case 'o':
        return _KdlTokenizerContext.octal;
      case 'x':
        return _KdlTokenizerContext.hexadecimal;
    }
  }

  _parseDecimal(String s) {
    try {
      if (RegExp("[.eE]").hasMatch(s)) {
        _checkFloat(s);
        return KdlToken(
            KdlTerm.decimal, BigDecimal.parse(_munchUnderscores(s)));
      }
      _checkInt(s);
      return _token(KdlTerm.integer, _parseInteger(_munchUnderscores(s), 10));
    } catch (e) {
      if (_nonInitialIdentifierChars
              .contains(String.fromCharCode(s.runes.first)) ||
          s.runes.skip(1).any(
              (c) => _nonIdentifierChars.contains(String.fromCharCode(c)))) {
        rethrow;
      }
      return _token(KdlTerm.ident, s);
    }
  }

  _checkFloat(String s) {
    if (!RegExp(r"^[+-]?[0-9][0-9_]*(\.[0-9][0-9_]*)?([eE][+-]?[0-9][0-9_]*)?$")
        .hasMatch(s)) {
      _fail("Invalid float: $s");
    }
  }

  _checkInt(String s) {
    if (!RegExp(r"^[+-]?[0-9][0-9_]*$").hasMatch(s)) {
      _fail("Invalid integer: $s");
    }
  }

  _parseHexadecimal(String s) {
    if (!RegExp(r"^[+-]?[0-9a-fA-F][0-9a-fA-F_]*$").hasMatch(s)) {
      _fail("Invalid hexadecimal: $s");
    }
    return _token(KdlTerm.integer, _parseInteger(_munchUnderscores(s), 16));
  }

  _parseOctal(String s) {
    if (!RegExp(r"^[+-]?[0-7][0-7_]*$").hasMatch(s)) {
      _fail("Invalid octal: $s");
    }
    return _token(KdlTerm.integer, _parseInteger(_munchUnderscores(s), 8));
  }

  _parseBinary(String s) {
    if (!RegExp(r"^[+-]?[01][01_]*$").hasMatch(s)) _fail("Invalid binary: $s");
    return _token(KdlTerm.integer, _parseInteger(_munchUnderscores(s), 2));
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

  static final _unescapeWsPattern =
      "[${whitespace.map(RegExp.escape).join()}${newlines.map(RegExp.escape).join()}\\r]+";
  static final _unescapePattern = RegExp("\\\\(?:$_unescapeWsPattern|[^u])");
  static final _unescapeNonWsPattern = RegExp(r"\\(?:[^u])");

  _unescapeNonWs(String string) {
    return _unescapeRgx(string, _unescapeNonWsPattern);
  }

  _unescape(String string) {
    return _unescapeRgx(string, _unescapePattern);
  }

  _unescapeRgx(String string, RegExp rgx) {
    return string.replaceAllMapped(rgx, (match) {
      return _replaceEsc(match.group(0));
    }).replaceAllMapped(RegExp(r"\\u\{[0-9a-fA-F]{1,6}\}"), (match) {
      String m = match.group(0) ?? '';
      int i = int.parse(m.substring(3, m.length - 1), radix: 16);
      if (i < 0 || i > 0x10FFFF || (i >= 0xD800 && i <= 0xDFFF)) {
        _fail("Invalid code point $m");
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
        if (m != null && RegExp("\\\\$_unescapeWsPattern").hasMatch(m)) {
          return '';
        }
        _fail("Unexpected escape '$m'");
    }
  }

  _parseInteger(String string, int radix) {
    try {
      return int.parse(string, radix: radix);
    } on FormatException {
      return BigInt.parse(string, radix: radix);
    }
  }

  _dedent(String string) {
    var [...lines, indent] = string.split(_newlinesPattern);
    if (!_wsStar.hasMatch(indent)) {
      _fail("Invalid multiline string final line");
    }

    var valid = RegExp("${RegExp.escape(indent)}(.*)");

    return lines.map((line) {
      if (_wsStar.hasMatch(line)) {
        return '';
      }
      var m = valid.matchAsPrefix(line);
      if (m != null) {
        return m.group(1);
      }
      _fail("Invalid multiline string indentation");
    }).join("\n");
  }
}

/// Tokenizer for KDLV1Parser
class KdlV1Tokenizer extends KdlTokenizer {
  static final _symbols = {
    '{': KdlTerm.lbrace,
    '}': KdlTerm.rbrace,
    '(': KdlTerm.lparen,
    ')': KdlTerm.rparen,
    ';': KdlTerm.semicolon,
    '=': KdlTerm.equals
  };

  static const _newlines = ["\u000A", "\u0085", "\u000C", "\u2028", "\u2029"];
  static final _newlinesPattern =
      RegExp("${_newlines.map(RegExp.escape).join('|')}|\\r\\n?");

  static final _nonIdentifierChars = [
    null,
    ...KdlTokenizer.whitespace,
    ..._newlines,
    ..._symbols.keys,
    "\r",
    "\\",
    "<",
    ">",
    "[",
    "]",
    '"',
    ",",
    "/",
    ..._charRange(0x0000, 0x0020),
  ];
  static final _nonInitialIdentifierChars = [
    ..._nonIdentifierChars,
    List.generate(10, (index) => index.toString())
  ];

  /// Construct a new KDL V1 Tokenizer
  KdlV1Tokenizer(super.str);

  static final _versionPattern = RegExp(
      "\\/-${KdlTokenizer._ws}*kdl-version${KdlTokenizer._ws}+(\\d+)${KdlTokenizer._ws}*${_newlinesPattern.pattern}");

  @override
  versionDirective() {
    var match = _versionPattern.matchAsPrefix(_str);
    if (match == null) return null;
    var m = match.group(1);
    if (m == null) return null;
    return int.parse(m);
  }

  @override
  KdlToken _readToken() {
    _context = null;
    _previousContext = null;
    _lineAtStart = _line;
    _columnAtStart = _column;
    while (true) {
      var c = _char(_index);
      if (_context == null) {
        if (c == null) {
          if (_done) {
            return _token(KdlTerm.eof, null);
          }
          _done = true;
          return _token(KdlTerm.eof, '');
        } else if (c == '"') {
          _context = _KdlTokenizerContext.string;
          _buffer = '';
          _traverse(1);
        } else if (c == 'r') {
          if (_char(_index + 1) == '"') {
            _context = _KdlTokenizerContext.rawstring;
            _traverse(2);
            _rawstringHashes = 0;
            _buffer = '';
            continue;
          } else if (_char(_index + 1) == '#') {
            var i = _index + 1;
            _rawstringHashes = 0;
            while (_char(i) == '#') {
              _rawstringHashes += 1;
              i += 1;
            }
            if (_char(i) == '"') {
              _context = _KdlTokenizerContext.rawstring;
              _traverse(_rawstringHashes + 2);
              _buffer = '';
              continue;
            }
          }
          _context = _KdlTokenizerContext.ident;
          _buffer = c;
          _traverse(1);
        } else if (c == '-') {
          var n = _char(_index + 1);
          var n2 = _char(_index + 2);
          if (n != null && RegExp(r"[0-9]").hasMatch(n)) {
            if (n == '0' && n2 != null && RegExp(r"[box]").hasMatch(n2)) {
              _context = _integerContext(n2);
              _traverse(2);
            } else {
              _context = _KdlTokenizerContext.decimal;
            }
          } else {
            _context = _KdlTokenizerContext.ident;
          }
          _buffer = c;
          _traverse(1);
        } else if (RegExp(r"[0-9+]").hasMatch(c)) {
          var n = _char(_index + 1);
          var n2 = _char(_index + 2);
          if (c == '0' && n != null && RegExp("[box]").hasMatch(n)) {
            _buffer = '';
            _context = _integerContext(n);
            _traverse(2);
          } else if (c == '+' && n == '0' && RegExp("[box]").hasMatch(n2)) {
            _buffer = c;
            _context = _integerContext(n2);
            _traverse(3);
          } else {
            _buffer = c;
            _context = _KdlTokenizerContext.decimal;
            _traverse(1);
          }
        } else if (c == "\\") {
          var t = KdlTokenizer(_str, start: _index + 1);
          var la = t.nextToken();
          if (la.type == KdlTerm.newline || la.type == KdlTerm.eof) {
            _buffer = "$c${la.value}";
            _context = _KdlTokenizerContext.whitespace;
            _traverseTo(t._index);
            continue;
          } else if (la.type == KdlTerm.whitespace) {
            var lan = t.nextToken();
            if (lan.type == KdlTerm.newline || lan.type == KdlTerm.eof) {
              _buffer = "$c${la.value}";
              if (lan.type == KdlTerm.newline) _buffer += "\n";
              _context = _KdlTokenizerContext.whitespace;
              _traverseTo(t._index);
              continue;
            }
          }
          _fail("Unexpected '\\'");
        } else if (_symbols.containsKey(c)) {
          if (c == '(') {
            _inType = true;
          } else if (c == ')') {
            _inType = false;
          }
          _traverse(1);
          return _token(_symbols[c]!, c);
        } else if (c == "\r" || _newlines.contains(c)) {
          String nl = _expectNewline(_index);
          _traverse(nl.runes.length);
          return _token(KdlTerm.newline, nl);
        } else if (c == "/") {
          var n = _char(_index + 1);
          if (n == '/') {
            if (_inType || _lastToken?.type == KdlTerm.rparen) {
              _fail("Unexpected '/'");
            }
            _context = _KdlTokenizerContext.singleLineComment;
            _traverse(2);
          } else if (n == '*') {
            if (_inType || _lastToken?.type == KdlTerm.rparen) {
              _fail("Unexpected '/'");
            }
            _commentNesting = 1;
            _context = _KdlTokenizerContext.multiLineComment;
            _traverse(2);
          } else if (n == '-') {
            _traverse(2);
            return _token(KdlTerm.slashdash, '/-');
          } else {
            _fail("Unexpected character '$c'");
          }
        } else if (KdlTokenizer.whitespace.contains(c)) {
          _buffer = c;
          _context = _KdlTokenizerContext.whitespace;
          _traverse(1);
        } else if (!_nonInitialIdentifierChars.contains(c)) {
          _buffer = c;
          _context = _KdlTokenizerContext.ident;
          _traverse(1);
        } else {
          _fail("Unexpected character '$c'");
        }
      } else {
        switch (_context) {
          case _KdlTokenizerContext.ident:
            if (!_nonIdentifierChars.contains(c)) {
              _buffer += c;
              _traverse(1);
              break;
            } else {
              switch (_buffer) {
                case 'true':
                  return _token(KdlTerm.trueKeyword, true);
                case 'false':
                  return _token(KdlTerm.falseKeyword, false);
                case 'null':
                  return _token(KdlTerm.nullKeyword, null);
                default:
                  return _token(KdlTerm.ident, _buffer);
              }
            }
          case _KdlTokenizerContext.string:
            switch (c) {
              case '\\':
                _buffer += c;
                var c2 = _char(_index + 1);
                _buffer += c2;
                if (_newlines.contains(c2)) {
                  var i = 2;
                  while (_newlines.contains(c2 = _char(_index + i))) {
                    _buffer += c2;
                    i += 1;
                  }
                  _traverse(i);
                } else {
                  _traverse(2);
                }
                break;
              case '"':
                _traverse(1);
                return _token(KdlTerm.string, _unescape(_buffer));
              case '':
              case null:
                _fail("Unterminated string literal");
              default:
                _buffer += c;
                _traverse(1);
                break;
            }
            break;
          case _KdlTokenizerContext.rawstring:
            if (c == null) {
              _fail("Unterminated rawstring literal");
            }

            if (c == '"') {
              var h = 0;
              while (_char(_index + 1 + h) == '#' && h < _rawstringHashes) {
                h += 1;
              }
              if (h == _rawstringHashes) {
                _traverse(1 + h);
                return _token(KdlTerm.rawstring, _buffer);
              }
            }
            _buffer += c;
            _traverse(1);
            break;
          case _KdlTokenizerContext.decimal:
            if (c != null && RegExp(r"[0-9.\-+_eE]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
            } else if (KdlTokenizer.whitespace.contains(c) ||
                _newlines.contains(c) ||
                c == null) {
              return _parseDecimal(_buffer);
            } else {
              _fail("Unexpected '$c'");
            }
            break;
          case _KdlTokenizerContext.hexadecimal:
            if (c != null && RegExp(r"[0-9a-fA-F_]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
            } else if (KdlTokenizer.whitespace.contains(c) ||
                _newlines.contains(c) ||
                c == null) {
              return _parseHexadecimal(_buffer);
            } else {
              _fail("Unexpected '$c'");
            }
            break;
          case _KdlTokenizerContext.octal:
            if (c != null && RegExp(r"[0-7_]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
            } else if (KdlTokenizer.whitespace.contains(c) ||
                _newlines.contains(c) ||
                c == null) {
              return _parseOctal(_buffer);
            } else {
              _fail("Unexpected '$c'");
            }
            break;
          case _KdlTokenizerContext.binary:
            if (c != null && RegExp(r"[01_]").hasMatch(c)) {
              _buffer += c;
              _traverse(1);
            } else if (KdlTokenizer.whitespace.contains(c) ||
                _newlines.contains(c) ||
                c == null) {
              return _parseBinary(_buffer);
            } else {
              _fail("Unexpected '$c'");
            }
            break;
          case _KdlTokenizerContext.singleLineComment:
            if (_newlines.contains(c) || c == "\r") {
              _context = null;
              _columnAtStart = _column;
              continue;
            } else if (c == null) {
              _done = true;
              return _token(KdlTerm.eof, '');
            } else {
              _traverse(1);
            }
            break;
          case _KdlTokenizerContext.multiLineComment:
            var n = _char(_index + 1);
            if (c == '/' && n == '*') {
              _commentNesting += 1;
              _traverse(2);
            } else if (c == '*' && n == '/') {
              _commentNesting -= 1;
              _traverse(2);
              if (_commentNesting == 0) {
                _revertContext();
              }
            } else {
              _traverse(1);
            }
            break;
          case _KdlTokenizerContext.whitespace:
            if (KdlTokenizer.whitespace.contains(c)) {
              _buffer += c;
              _traverse(1);
            } else if (c == "\\") {
              var t = KdlTokenizer(_str, start: _index + 1);
              var la = t.nextToken();
              if (la.type == KdlTerm.newline || la.type == KdlTerm.eof) {
                _buffer += "$c${la.value}";
                _traverseTo(t._index);
                continue;
              } else if (la.type == KdlTerm.whitespace) {
                var lan = t.nextToken();
                if (lan.type == KdlTerm.newline || lan.type == KdlTerm.eof) {
                  _buffer += "$c${la.value}";
                  if (lan.type == KdlTerm.newline) _buffer += "\n";
                  _traverseTo(t._index);
                  continue;
                }
              }
              _fail("Unexpected '\\'");
            } else if (c == "/" && _char(_index + 1) == '*') {
              _commentNesting = 1;
              _context = _KdlTokenizerContext.multiLineComment;
              _traverse(2);
            } else {
              return _token(KdlTerm.whitespace, _buffer);
            }
            break;
          case null:
            _fail("Unexpected null context");
          default:
            _fail("Unknown context $_context");
        }
      }
    }
  }

  @override
  _parseDecimal(String s) {
    if (RegExp("[.eE]").hasMatch(s)) {
      _checkFloat(s);
      return _token(KdlTerm.decimal, BigDecimal.parse(_munchUnderscores(s)));
    }
    _checkInt(s);
    return _token(KdlTerm.integer, _parseInteger(_munchUnderscores(s), 10));
  }

  @override
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
      case r'\/':
        return '/';
      default:
        if (m != null &&
            RegExp("\\\\${KdlTokenizer._unescapeWsPattern}").hasMatch(m)) {
          return '';
        }
        _fail("Unexpected escape '$m'");
    }
  }
}
