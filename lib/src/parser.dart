import 'package:kdl/src/document.dart';
import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/types.dart';

class KdlParser {
  late KdlTokenizer tokenizer;
  late Map<String, Function> typeParsers;
  int depth = 0;

  parse(String string, { Map<String, Function> typeParsers = const {}, bool parseTypes = true }) {
    this.tokenizer = KdlTokenizer(string);

    if (parseTypes) {
      this.typeParsers = { ...KdlTypes.MAPPING, ...typeParsers };
    } else {
      this.typeParsers = {};
    }

    return _document();
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
      tokenizer.nextToken();
      _wsStar();
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

    switch (tokenizer.peekToken()[0]) {
      case KdlToken.WS:
      case KdlToken.LBRACE:
        _argsPropsChildren(node);
        break;
      case KdlToken.SEMICOLON:
        tokenizer.nextToken();
        break;
      case KdlToken.LPAREN:
        throw "Unexpected (";
    }

    if (commented) return null;

    if (type != null) {
      return node.asType(type, typeParsers[type]);
    }
    return node;
  }

  _identifier() {
    var t = tokenizer.peekToken();
    if (t[0] == KdlToken.IDENT || t[0] == KdlToken.STRING || t[0] == KdlToken.RAWSTRING) {
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
    while (true) {
      _wsStar();
      switch (tokenizer.peekToken()[0]) {
      case KdlToken.IDENT:
        var t = tokenizer.peekTokenAfterNext();
        if (t[0] == KdlToken.EQUALS) {
          var p = _prop();
          if (!commented) {
            node.properties[p[0]] = p[1];
          }
        } else {
          var v = _value();
          if (!commented) {
            node.arguments.add(v);
          }
        }
        commented = false;
        break;
      case KdlToken.LBRACE:
        this.depth += 1;
        var children = _children();
        if (!commented) {
          node.children = children;
        }
        _expectNodeTerm();
        return;
      case KdlToken.RBRACE:
        if (this.depth == 0) throw "Unexpected }";
        this.depth -= 1;
        return;
      case KdlToken.SLASHDASH:
        commented = true;
        tokenizer.nextToken();
        _wsStar();
        break;
      case KdlToken.NEWLINE:
      case KdlToken.EOF:
      case KdlToken.SEMICOLON:
        tokenizer.nextToken();
        return;
      case KdlToken.STRING:
        var t = tokenizer.peekTokenAfterNext();
        if (t[0] == KdlToken.EQUALS) {
          var p = _prop();
          if (!commented) {
            node.properties[p[0]] = p[1];
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
