import 'package:kdl/src/document.dart';
import 'package:kdl/src/tokenizer.dart';

class KdlParser {
  KdlTokenizer tokenizer;

  parse(String string) {
    this.tokenizer = KdlTokenizer(string);

    return _document();
  }

  _document() {
    var nodes = _nodes();
    _eatLinespaces();
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
    _eatLinespaces();

    var commented = false;
    if (tokenizer.peekToken()[0] == KdlToken.SLASHDASH) {
      tokenizer.nextToken();
      commented = true;
    }

    var node;
    try {
      node = KdlNode(_identifier());
    } catch (_) {
      return false;
    }

    _argsPropsChildren(node);

    if (commented) return null;
    return node;
  }

  _identifier() {
    _eatWhitespace();
    return _expect(KdlToken.IDENT);
  }

  _eatWhitespace() {
    var t = tokenizer.peekToken();
    if (t[0] == KdlToken.WS) tokenizer.nextToken();
  }

  _eatLinespaces() {
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
      _eatWhitespace();
      switch (tokenizer.peekToken()[0]) {
      case KdlToken.IDENT:
        var p = _prop();
        if (!commented) {
          node.properties[p[0]] = p[1];
        }
        commented = false;
        break;
      case KdlToken.LPAREN:
        var children = _children();
        if (!commented) {
          node.children = children;
        }
        _expectNodeTerm();
        return;
      case KdlToken.SLASHDASH:
        commented = true;
        tokenizer.nextToken();
        break;
      case KdlToken.NEWLINE:
      case KdlToken.EOF:
      case KdlToken.SEMICOLON:
        tokenizer.nextToken();
        return;
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
    var name = _expect(KdlToken.IDENT);
    _expect(KdlToken.EQUALS);
    var value = _value();
    return [name, value];
  }

  _children() {
    _expect(KdlToken.LPAREN);
    var nodes = _nodes();
    _eatLinespaces();
    _expect(KdlToken.RPAREN);
    return nodes;
  }

  _value() {
    var t = tokenizer.nextToken();
    switch (t[0]) {
      case KdlToken.STRING:
      case KdlToken.RAWSTRING:
        return KdlString(t[1]);
      case KdlToken.INTEGER:
        return KdlInt(t[1]);
      case KdlToken.FLOAT:
        return KdlFloat(t[1]);
      case KdlToken.TRUE:
      case KdlToken.FALSE:
        return KdlBool(t[1]);
      case KdlToken.NULL:
        return KdlNull();
      default:
        throw "Expected value, got ${t[0]}";
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
    _eatWhitespace();
    var t = tokenizer.peekToken()[0];
    if (t == KdlToken.NEWLINE || t == KdlToken.SEMICOLON || t == KdlToken.EOF) {
      tokenizer.nextToken();
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
