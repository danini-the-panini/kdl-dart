import 'package:kdl/src/document.dart';
import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/types.dart';

class KdlParser {
  late KdlTokenizer tokenizer;
  late Map<String, Function> typeParsers;
  int depth = 0;
  int parserVersion = 2;

  KdlDocument parse(String string,
      {Map<String, Function> typeParsers = const {}, bool parseTypes = true}) {
    this.tokenizer = KdlTokenizer(string);
    _checkVersion();

    if (parseTypes) {
      this.typeParsers = {...KdlTypes.MAPPING, ...typeParsers};
    } else {
      this.typeParsers = {};
    }

    return _document();
  }

  void _checkVersion() {
    var docVersion = tokenizer.versionDirective();
    if (docVersion == null) return;
    if (docVersion != parserVersion) {
      throw "Version mismatch, document specified v${docVersion}, but this is a v${parserVersion} parser";
    }
  }

  KdlDocument _document() {
    var nodes = _nodes();
    _linespaceStar();
    _expectEndOfFile();
    return KdlDocument(nodes);
  }

  List<KdlNode> _nodes() {
    List<KdlNode> nodes = [];
    var n;
    while ((n = _node()) != false) {
      if (n != null) nodes.add(n);
    }
    return nodes;
  }

  _node() {
    _linespaceStar();

    var commented = false;
    if (tokenizer.peekToken().type == KdlTerm.SLASHDASH) {
      _slashdash();
      commented = true;
    }

    var node, type;
    try {
      type = _type();
      node = KdlNode(_identifier());
    } catch (error) {
      if (type != null) throw error;
      return false;
    }

    _argsPropsChildren(node);

    if (commented) return null;

    if (type != null) {
      return node.asType(type, typeParsers[type]);
    }
    return node;
  }

  String _identifier() {
    var t = tokenizer.peekToken();
    if (t.type == KdlTerm.IDENT ||
        t.type == KdlTerm.STRING ||
        t.type == KdlTerm.RAWSTRING) {
      tokenizer.nextToken();
      return t.value;
    }
    throw "Expected identifier, got ${t.type}";
  }

  void _wsStar() {
    var t = tokenizer.peekToken();
    while (t.type == KdlTerm.WS) {
      tokenizer.nextToken();
      t = tokenizer.peekToken();
    }
  }

  void _linespaceStar() {
    while (_isLinespace(tokenizer.peekToken())) {
      tokenizer.nextToken();
    }
  }

  bool _isLinespace(KdlToken t) {
    return (t.type == KdlTerm.NEWLINE || t.type == KdlTerm.WS);
  }

  void _argsPropsChildren(KdlNode node) {
    var commented = false;
    var hasChildren = false;
    while (true) {
      var peek = tokenizer.peekToken().type;
      switch (peek) {
        case KdlTerm.WS:
          _wsStar();
          peek = tokenizer.peekToken().type;
          if (peek == KdlTerm.SLASHDASH) {
            _slashdash();
            peek = tokenizer.peekToken().type;
            commented = true;
          }
          switch (peek) {
            case KdlTerm.STRING:
            case KdlTerm.IDENT:
              if (hasChildren) throw "Unexpected ${peek}";
              var t = tokenizer.peekTokenAfterNext();
              if (t.type == KdlTerm.EQUALS) {
                var p = _prop();
                if (!commented) node.properties[p[0]] = p[1];
              } else {
                var v = _value();
                if (!commented) node.arguments.add(v);
              }
              commented = false;
              break;
            case KdlTerm.NEWLINE:
            case KdlTerm.EOF:
            case KdlTerm.SEMICOLON:
              tokenizer.nextToken();
              return;
            case KdlTerm.LBRACE:
              _lbrace(node, commented);
              hasChildren = true;
              commented = false;
              break;
            case KdlTerm.RBRACE:
              _rbrace();
              return;
            default:
              var v = _value();
              if (hasChildren) throw "Unexpected ${peek}";
              if (!commented) node.arguments.add(v);
              commented = false;
              break;
          }
          break;
        case KdlTerm.EOF:
        case KdlTerm.SEMICOLON:
        case KdlTerm.NEWLINE:
          tokenizer.nextToken();
          return;
        case KdlTerm.LBRACE:
          _lbrace(node, commented);
          hasChildren = true;
          commented = false;
          break;
        case KdlTerm.RBRACE:
          _rbrace();
          return;
        default:
          throw "Unexpected ${peek}";
      }
    }
  }

  void _lbrace(KdlNode node, bool commented) {
    if (!commented && node.hasChildren) throw "Unexpected {";
    depth += 1;
    var children = _children();
    depth -= 1;
    if (!commented) {
      node.children = children;
    }
  }

  void _rbrace() {
    if (depth == 0) throw "Unexpected }";
  }

  _prop() {
    var name = _identifier();
    _expect(KdlTerm.EQUALS);
    var value = _value();
    return [name, value];
  }

  List<KdlNode> _children() {
    _expect(KdlTerm.LBRACE);
    var nodes = _nodes();
    _linespaceStar();
    _expect(KdlTerm.RBRACE);
    return nodes;
  }

  KdlValue _value() {
    var type = _type();
    var t = tokenizer.nextToken();
    var v = _valueWithoutType(t);
    if (type == null) {
      return v;
    } else {
      return v.asType(type, typeParsers[type]);
    }
  }

  KdlValue _valueWithoutType(KdlToken t) {
    switch (t.type) {
      case KdlTerm.IDENT:
      case KdlTerm.STRING:
      case KdlTerm.RAWSTRING:
        return KdlString(t.value);
      case KdlTerm.INTEGER:
        return KdlInt(t.value);
      case KdlTerm.DECIMAL:
        return KdlBigDecimal(t.value);
      case KdlTerm.DOUBLE:
        return KdlDouble(t.value);
      case KdlTerm.TRUE:
      case KdlTerm.FALSE:
        return KdlBool(t.value);
      case KdlTerm.NULL:
        return KdlNull();
      default:
        throw "Expected value, got ${t.type}";
    }
  }

  String? _type() {
    if (tokenizer.peekToken().type != KdlTerm.LPAREN) return null;
    _expect(KdlTerm.LPAREN);
    _wsStar();
    var type = _identifier();
    _wsStar();
    _expect(KdlTerm.RPAREN);
    _wsStar();
    return type;
  }

  void _slashdash() {
    var t = tokenizer.nextToken().type;
    if (t != KdlTerm.SLASHDASH) {
      throw "Expected SLASHDASH, found ${t}";
    }
    _linespaceStar();
    var peek = tokenizer.peekToken().type;
    switch (peek) {
      case KdlTerm.RBRACE:
      case KdlTerm.EOF:
      case KdlTerm.SEMICOLON:
        throw "Unexpected ${peek} after SLASHDASH";
      default:
        break;
    }
  }

  _expect(KdlTerm type) {
    var t = tokenizer.peekToken().type;
    if (t == type) {
      return tokenizer.nextToken().value;
    } else {
      throw "Expected ${type}, got ${t}";
    }
  }

  void _expectEndOfFile() {
    var t = tokenizer.peekToken().type;
    if (t == KdlTerm.EOF) return;

    throw "Expected EOF, got ${t}";
  }
}
