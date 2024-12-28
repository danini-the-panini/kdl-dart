import 'package:kdl/src/document.dart';
import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/types.dart';

class KdlParser {
  late KdlTokenizer tokenizer;
  late Map<String, Function> typeParsers;
  int depth = 0;
  int parserVersion = 2;

  parse(String string,
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

  _checkVersion() {
    var docVersion = tokenizer.versionDirective();
    if (docVersion == null) return;
    if (docVersion != parserVersion) {
      throw "Version mismatch, document specified v${docVersion}, but this is a v${parserVersion} parser";
    }
  }

  _document() {
    var nodes = _nodes();
    _linespaceStar();
    _expectEndOfFile();
    return KdlDocument(nodes);
  }

  _nodes() {
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
    if (tokenizer.peekToken()[0] == KdlToken.SLASHDASH) {
      // print('node slashdashing...');
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
    // print("done with argsPropsChildren for ${node.name}");

    if (commented) return null;

    if (type != null) {
      return node.asType(type, typeParsers[type]);
    }
    return node;
  }

  _identifier() {
    var t = tokenizer.peekToken();
    if (t[0] == KdlToken.IDENT ||
        t[0] == KdlToken.STRING ||
        t[0] == KdlToken.RAWSTRING) {
      tokenizer.nextToken();
      return t[1];
    }
    throw "Expected identifier, got ${t[0]}";
  }

  _wsStar() {
    var t = tokenizer.peekToken();
    while (t[0] == KdlToken.WS) {
      tokenizer.nextToken();
      t = tokenizer.peekToken();
    }
  }

  _linespaceStar() {
    while (_isLinespace(tokenizer.peekToken())) {
      tokenizer.nextToken();
    }
  }

  _isLinespace(t) {
    return (t[0] == KdlToken.NEWLINE || t[0] == KdlToken.WS);
  }

  _argsPropsChildren(KdlNode node) {
    var commented = false;
    var hasChildren = false;
    while (true) {
      var peek = tokenizer.peekToken()[0];
      switch (peek) {
        case KdlToken.WS:
          _wsStar();
          peek = tokenizer.peekToken()[0];
          if (peek == KdlToken.SLASHDASH) {
            // print('slashdashing...');
            _slashdash();
            peek = tokenizer.peekToken()[0];
            commented = true;
          }
          switch (peek) {
            case KdlToken.STRING:
            case KdlToken.IDENT:
              if (hasChildren) throw "Unexpected ${peek}";
              var t = tokenizer.peekTokenAfterNext();
              if (t[0] == KdlToken.EQUALS) {
                var p = _prop();
                if (!commented) node.properties[p[0]] = p[1];
              } else {
                var v = _value();
                if (!commented) node.arguments.add(v);
              }
              commented = false;
              break;
            case KdlToken.NEWLINE:
            case KdlToken.EOF:
            case KdlToken.SEMICOLON:
              tokenizer.nextToken();
              return;
            case KdlToken.LBRACE:
              _lbrace(node, commented);
              hasChildren = true;
              commented = false;
              break;
            case KdlToken.RBRACE:
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
        case KdlToken.EOF:
        case KdlToken.SEMICOLON:
        case KdlToken.NEWLINE:
          tokenizer.nextToken();
          return;
        case KdlToken.LBRACE:
          _lbrace(node, commented);
          hasChildren = true;
          commented = false;
          break;
        case KdlToken.RBRACE:
          _rbrace();
          return;
        default:
          throw "Unexpected ${peek}";
      }
    }
  }

  _lbrace(KdlNode node, bool commented) {
    if (!commented && node.hasChildren) throw "Unexpected {";
    depth += 1;
    var children = _children();
    depth -= 1;
    if (!commented) {
      node.children = children;
    }
  }

  _rbrace() {
    if (depth == 0) throw "Unexpected }";
  }

  _prop() {
    var name = _identifier();
    _expect(KdlToken.EQUALS);
    var value = _value();
    return [name, value];
  }

  _children() {
    _expect(KdlToken.LBRACE);
    var nodes = _nodes();
    _linespaceStar();
    _expect(KdlToken.RBRACE);
    return nodes;
  }

  _value() {
    var type = _type();
    var t = tokenizer.nextToken();
    var v = _valueWithoutType(t);
    if (type == null) {
      return v;
    } else {
      return v.asType(type, typeParsers[type]);
    }
  }

  _valueWithoutType(List t) {
    switch (t[0]) {
      case KdlToken.IDENT:
      case KdlToken.STRING:
      case KdlToken.RAWSTRING:
        return KdlString(t[1]);
      case KdlToken.INTEGER:
        return KdlInt(t[1]);
      case KdlToken.DECIMAL:
        return KdlBigDecimal(t[1]);
      case KdlToken.DOUBLE:
        return KdlDouble(t[1]);
      case KdlToken.TRUE:
      case KdlToken.FALSE:
        return KdlBool(t[1]);
      case KdlToken.NULL:
        return KdlNull();
      default:
        throw "Expected value, got ${t[0]}";
    }
  }

  _type() {
    if (tokenizer.peekToken()[0] != KdlToken.LPAREN) return null;
    _expect(KdlToken.LPAREN);
    _wsStar();
    var type = _identifier();
    _wsStar();
    _expect(KdlToken.RPAREN);
    _wsStar();
    return type;
  }

  _slashdash() {
    var t = tokenizer.nextToken()[0];
    if (t != KdlToken.SLASHDASH) {
      throw "Expected SLASHDASH, found ${t}";
    }
    _linespaceStar();
    var peek = tokenizer.peekToken()[0];
    switch (peek) {
      case KdlToken.RBRACE:
      case KdlToken.EOF:
      case KdlToken.SEMICOLON:
        throw "Unexpected ${peek} after SLASHDASH";
    }
  }

  _expect(KdlToken type) {
    var t = tokenizer.peekToken()[0];
    if (t == type) {
      return tokenizer.nextToken()[1];
    } else {
      throw "Expected ${type}, got ${t}";
    }
  }

  _expectNodeTerm() {
    _wsStar();
    var t = tokenizer.peekToken()[0];
    if (t == KdlToken.NEWLINE || t == KdlToken.SEMICOLON || t == KdlToken.EOF) {
      tokenizer.nextToken();
    } else if (t == KdlToken.RBRACE) {
      return;
    } else {
      throw "Unexpected ${t}";
    }
  }

  _expectEndOfFile() {
    var t = tokenizer.peekToken()[0];
    if (t == KdlToken.EOF || t == false) return;

    throw "Expected EOF, got ${t}";
  }
}
