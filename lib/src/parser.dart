import 'package:kdl/src/document.dart';
import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/types.dart';
import 'package:kdl/src/exception.dart';

/// KDL 2.0.0 Parser
class KdlParser {
  /// Default KDLValue types for well-known types
  static const Map<String, KdlTypeParser<KdlValue>> defaultValueTypes = {
    'date-time': KdlDateTime.convert,
    'time': KdlTime.convert,
    'date': KdlDate.convert,
    'duration': KdlDuration.convert,
    'decimal': KdlDecimal.convert,
    'currency': KdlCurrency.convert,
    'country-2': KdlCountry2.convert,
    'country-3': KdlCountry3.convert,
    'country-subdivision': KdlCountrySubdivision.convert,
    'email': KdlEmail.convert,
    'idn-email': KdlIdnEmail.convert,
    'hostname': KdlHostname.convert,
    'idn-hostname': KdlIdnHostname.convert,
    'ipv4': KdlIPV4.convert,
    'ipv6': KdlIPV6.convert,
    'url': KdlUrl.convert,
    'url-reference': KdlUrlReference.convert,
    'irl': KdlIRL.convert,
    'irl-reference': KdlIrlReference.convert,
    'url-template': KdlUrlTemplate.convert,
    'uuid': KdlUuid.convert,
    'regex': KdlRegex.convert,
    'base64': KdlBase64.convert,
  };

  late KdlTokenizer _tokenizer;
  Map<String, KdlTypeParser<KdlValue>> _valueTypes = {};
  Map<String, KdlTypeParser<KdlNode>> _nodeTypes = {};
  int _depth = 0;
  int get _parserVersion => 2;

  /// Parse a string into a KdlDocument
  /// optionally passing in custom `valueTypes` and `nodeTypes`
  /// or turning off type parsing with `parseTypes: false`
  KdlDocument parse(String string,
      {Map<String, KdlTypeParser<KdlValue>> valueTypes = const {},
      Map<String, KdlTypeParser<KdlNode>> nodeTypes = const {},
      bool parseTypes = true}) {
    _tokenizer = _createTokenizer(string);
    _checkVersion();

    if (parseTypes) {
      _valueTypes = {...defaultValueTypes, ...valueTypes};
      _nodeTypes = nodeTypes;
    }

    return _document();
  }

  KdlTokenizer _createTokenizer(String string) {
    return KdlTokenizer(string);
  }

  void _checkVersion() {
    var docVersion = _tokenizer.versionDirective();
    if (docVersion == null) return;
    if (docVersion != _parserVersion) {
      throw KdlVersionMismatchException(docVersion, _parserVersion);
    }
  }

  KdlDocument _document() {
    var nodes = _nodeList();
    _linespaceStar();
    _expectEndOfFile();
    return KdlDocument(nodes);
  }

  List<KdlNode> _nodeList() {
    List<KdlNode> nodes = [];
    KdlNode? node;
    while (((node, _) = _node()).$2 != false) {
      if (node != null) nodes.add(node);
    }
    return nodes;
  }

  (KdlNode?, bool) _node() {
    _linespaceStar();

    var commented = false;
    if (_tokenizer.peekToken().type == KdlTerm.slashdash) {
      _slashdash();
      commented = true;
    }

    KdlNode node;
    String? ty;
    try {
      ty = _type();
      node = KdlNode(_identifier());
    } catch (error) {
      if (ty != null) rethrow;
      return (null, false);
    }

    _argsPropsChildren(node);

    if (commented) return (null, true);

    if (ty != null) {
      return (node.asType(ty, _nodeTypes[ty]), true);
    }
    return (node, true);
  }

  String _identifier() {
    var t = _tokenizer.peekToken();
    if (t.type == KdlTerm.ident ||
        t.type == KdlTerm.string ||
        t.type == KdlTerm.rawstring) {
      _tokenizer.nextToken();
      return t.value;
    }
    throw _ex("Expected identifier, got ${t.type}", t);
  }

  void _wsStar() {
    var t = _tokenizer.peekToken();
    while (t.type == KdlTerm.whitespace) {
      _tokenizer.nextToken();
      t = _tokenizer.peekToken();
    }
  }

  void _linespaceStar() {
    while (_isLinespace(_tokenizer.peekToken())) {
      _tokenizer.nextToken();
    }
  }

  bool _isLinespace(KdlToken t) {
    return (t.type == KdlTerm.newline || t.type == KdlTerm.whitespace);
  }

  void _argsPropsChildren(KdlNode node) {
    var commented = false;
    var hasChildren = false;
    while (true) {
      var peek = _tokenizer.peekToken();
      switch (peek.type) {
        case KdlTerm.whitespace:
        case KdlTerm.slashdash:
          _wsStar();
          peek = _tokenizer.peekToken();
          if (peek.type == KdlTerm.slashdash) {
            _slashdash();
            peek = _tokenizer.peekToken();
            commented = true;
          }
          switch (peek.type) {
            case KdlTerm.string:
            case KdlTerm.ident:
              if (hasChildren) throw _ex("Unexpected ${peek.type}", peek);
              var t = _tokenizer.peekTokenAfterNext();
              if (t.type == KdlTerm.equals) {
                var p = _prop();
                if (!commented) node.properties[p.$1] = p.$2;
              } else {
                var v = _value();
                if (!commented) node.arguments.add(v);
              }
              commented = false;
              break;
            case KdlTerm.newline:
            case KdlTerm.eof:
            case KdlTerm.semicolon:
              _tokenizer.nextToken();
              return;
            case KdlTerm.lbrace:
              _lbrace(node, commented);
              hasChildren = true;
              commented = false;
              break;
            case KdlTerm.rbrace:
              _rbrace();
              return;
            default:
              var v = _value();
              if (hasChildren) throw _ex("Unexpected ${peek.type}", peek);
              if (!commented) node.arguments.add(v);
              commented = false;
              break;
          }
          break;
        case KdlTerm.eof:
        case KdlTerm.semicolon:
        case KdlTerm.newline:
          _tokenizer.nextToken();
          return;
        case KdlTerm.lbrace:
          _lbrace(node, commented);
          hasChildren = true;
          commented = false;
          break;
        case KdlTerm.rbrace:
          _rbrace();
          return;
        default:
          throw _ex("Unexpected ${peek.type}", peek);
      }
    }
  }

  void _lbrace(KdlNode node, bool commented) {
    if (!commented && node.hasChildren) throw _ex("Unexpected {");
    _depth += 1;
    var children = _children();
    _depth -= 1;
    if (!commented) {
      node.children = children;
    }
  }

  void _rbrace() {
    if (_depth == 0) throw "Unexpected }";
  }

  (String, KdlValue) _prop() {
    var name = _identifier();
    _expect(KdlTerm.equals);
    var val = _value();
    return (name, val);
  }

  List<KdlNode> _children() {
    _expect(KdlTerm.lbrace);
    var nodes = _nodeList();
    _linespaceStar();
    _expect(KdlTerm.rbrace);
    return nodes;
  }

  KdlValue _value() {
    var ty = _type();
    var t = _tokenizer.nextToken();
    var v = _valueWithoutType(t);
    if (ty == null) {
      return v;
    } else {
      return v.asType(ty, _valueTypes[ty]);
    }
  }

  KdlValue _valueWithoutType(KdlToken t) {
    switch (t.type) {
      case KdlTerm.ident:
      case KdlTerm.string:
      case KdlTerm.rawstring:
        return KdlString(t.value);
      case KdlTerm.integer:
        return KdlInt(t.value);
      case KdlTerm.decimal:
        return KdlBigDecimal(t.value);
      case KdlTerm.double:
        return KdlDouble(t.value);
      case KdlTerm.trueKeyword:
      case KdlTerm.falseKeyword:
        return KdlBool(t.value);
      case KdlTerm.nullKeyword:
        return KdlNull();
      default:
        throw _ex("Expected value, got ${t.type}", t);
    }
  }

  String? _type() {
    if (_tokenizer.peekToken().type != KdlTerm.lparen) return null;
    _expect(KdlTerm.lparen);
    _wsStar();
    var ty = _identifier();
    _wsStar();
    _expect(KdlTerm.rparen);
    _wsStar();
    return ty;
  }

  void _slashdash() {
    var t = _tokenizer.nextToken();
    if (t.type != KdlTerm.slashdash) {
      throw _ex("Expected SLASHDASH, found ${t.type}", t);
    }
    _linespaceStar();
    var peek = _tokenizer.peekToken();
    switch (peek.type) {
      case KdlTerm.rbrace:
      case KdlTerm.eof:
      case KdlTerm.semicolon:
        throw _ex("Unexpected ${peek.type} after SLASHDASH", peek);
      default:
        break;
    }
  }

  _expect(KdlTerm type) {
    var t = _tokenizer.peekToken();
    if (t.type == type) {
      return _tokenizer.nextToken().value;
    } else {
      throw _ex("Expected $type, got ${t.type}", t);
    }
  }

  void _expectEndOfFile() {
    var t = _tokenizer.peekToken();
    if (t.type == KdlTerm.eof) return;

    throw _ex("Expected EOF, got ${t.type}", t);
  }

  KdlParseException _ex(String message, [KdlToken? token]) {
    token = token ?? _tokenizer.peekToken();
    return KdlParseException(message, token.line, token.column);
  }
}

/// KDL 1.0 Parser
class KdlV1Parser extends KdlParser {
  @override
  int get _parserVersion => 1;

  @override
  KdlTokenizer _createTokenizer(String string) {
    return KdlV1Tokenizer(string);
  }

  @override
  void _argsPropsChildren(KdlNode node) {
    var commented = false;
    while (true) {
      _wsStar();
      switch (_tokenizer.peekToken().type) {
        case KdlTerm.ident:
          var p = _prop();
          if (!commented) {
            node.properties[p.$1] = p.$2;
          }
          commented = false;
          break;
        case KdlTerm.lbrace:
          var childNodes = _children();
          if (!commented) {
            node.children = childNodes;
          }
          _expectNodeTerm();
          return;
        case KdlTerm.slashdash:
          commented = true;
          _tokenizer.nextToken();
          _wsStar();
          break;
        case KdlTerm.newline:
        case KdlTerm.eof:
        case KdlTerm.semicolon:
          _tokenizer.nextToken();
          return;
        case KdlTerm.string:
          var t = _tokenizer.peekTokenAfterNext();
          if (t.type == KdlTerm.equals) {
            var p = _prop();
            if (!commented) {
              node.properties[p.$1] = p.$2;
            }
          } else {
            var v = _value();
            if (!commented) {
              node.arguments.add(v);
            }
          }
          commented = false;
          break;
        default:
          var v = _value();
          if (!commented) {
            node.arguments.add(v);
          }
          commented = false;
          break;
      }
    }
  }

  @override
  KdlValue _valueWithoutType(KdlToken t) {
    switch (t.type) {
      case KdlTerm.string:
      case KdlTerm.rawstring:
        return KdlString(t.value);
      case KdlTerm.integer:
        return KdlInt(t.value);
      case KdlTerm.decimal:
        return KdlBigDecimal(t.value);
      case KdlTerm.double:
        return KdlDouble(t.value);
      case KdlTerm.trueKeyword:
      case KdlTerm.falseKeyword:
        return KdlBool(t.value);
      case KdlTerm.nullKeyword:
        return KdlNull();
      default:
        throw _ex("Expected value, got ${t.type}", t);
    }
  }

  @override
  String? _type() {
    if (_tokenizer.peekToken().type != KdlTerm.lparen) return null;
    _expect(KdlTerm.lparen);
    var ty = _identifier();
    _expect(KdlTerm.rparen);
    return ty;
  }

  _expectNodeTerm() {
    _wsStar();
    var t = _tokenizer.peekToken().type;
    if (t == KdlTerm.newline || t == KdlTerm.semicolon || t == KdlTerm.eof) {
      _tokenizer.nextToken();
    } else {
      throw "Unexpected $t";
    }
  }
}
