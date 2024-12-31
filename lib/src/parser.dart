import 'package:kdl/src/document.dart';
import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/types.dart';
import 'package:kdl/src/exception.dart';

class KdlParser {
  late KdlTokenizer tokenizer;
  late Map<String, Function> typeParsers;
  int depth = 0;
  int parserVersion = 2;

  KdlDocument parse(String string,
      {Map<String, Function> typeParsers = const {}, bool parseTypes = true}) {
    this.tokenizer = createTokenizer(string);
    _checkVersion();

    if (parseTypes) {
      this.typeParsers = {...KdlTypes.MAPPING, ...typeParsers};
    } else {
      this.typeParsers = {};
    }

    return document();
  }

  KdlTokenizer createTokenizer(String string) {
    return KdlTokenizer(string);
  }

  void _checkVersion() {
    var docVersion = tokenizer.versionDirective();
    if (docVersion == null) return;
    if (docVersion != parserVersion) {
      throw KdlVersionMismatchException(docVersion, parserVersion);
    }
  }

  KdlDocument document() {
    var nodes = nodeList();
    linespaceStar();
    expectEndOfFile();
    return KdlDocument(nodes);
  }

  List<KdlNode> nodeList() {
    List<KdlNode> nodes = [];
    var n;
    while ((n = node()) != false) {
      if (n != null) nodes.add(n);
    }
    return nodes;
  }

  node() {
    linespaceStar();

    var commented = false;
    if (tokenizer.peekToken().type == KdlTerm.SLASHDASH) {
      slashdash();
      commented = true;
    }

    var node, ty;
    try {
      ty = type();
      node = KdlNode(identifier());
    } catch (error) {
      if (ty != null) throw error;
      return false;
    }

    argsPropsChildren(node);

    if (commented) return null;

    if (ty != null) {
      return node.asType(ty, typeParsers[ty]);
    }
    return node;
  }

  String identifier() {
    var t = tokenizer.peekToken();
    if (t.type == KdlTerm.IDENT ||
        t.type == KdlTerm.STRING ||
        t.type == KdlTerm.RAWSTRING) {
      tokenizer.nextToken();
      return t.value;
    }
    throw ex("Expected identifier, got ${t.type}", t);
  }

  void wsStar() {
    var t = tokenizer.peekToken();
    while (t.type == KdlTerm.WS) {
      tokenizer.nextToken();
      t = tokenizer.peekToken();
    }
  }

  void linespaceStar() {
    while (isLinespace(tokenizer.peekToken())) {
      tokenizer.nextToken();
    }
  }

  bool isLinespace(KdlToken t) {
    return (t.type == KdlTerm.NEWLINE || t.type == KdlTerm.WS);
  }

  void argsPropsChildren(KdlNode node) {
    var commented = false;
    var hasChildren = false;
    while (true) {
      var peek = tokenizer.peekToken();
      switch (peek.type) {
        case KdlTerm.WS:
          wsStar();
          peek = tokenizer.peekToken();
          if (peek.type == KdlTerm.SLASHDASH) {
            slashdash();
            peek = tokenizer.peekToken();
            commented = true;
          }
          switch (peek.type) {
            case KdlTerm.STRING:
            case KdlTerm.IDENT:
              if (hasChildren) throw ex("Unexpected ${peek.type}", peek);
              var t = tokenizer.peekTokenAfterNext();
              if (t.type == KdlTerm.EQUALS) {
                var p = prop();
                if (!commented) node.properties[p[0]] = p[1];
              } else {
                var v = value();
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
              lbrace(node, commented);
              hasChildren = true;
              commented = false;
              break;
            case KdlTerm.RBRACE:
              rbrace();
              return;
            default:
              var v = value();
              if (hasChildren) throw ex("Unexpected ${peek.type}", peek);
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
          lbrace(node, commented);
          hasChildren = true;
          commented = false;
          break;
        case KdlTerm.RBRACE:
          rbrace();
          return;
        default:
          throw ex("Unexpected ${peek.type}", peek);
      }
    }
  }

  void lbrace(KdlNode node, bool commented) {
    if (!commented && node.hasChildren) throw ex("Unexpected {");
    depth += 1;
    var childNodes = children();
    depth -= 1;
    if (!commented) {
      node.children = childNodes;
    }
  }

  void rbrace() {
    if (depth == 0) throw "Unexpected }";
  }

  prop() {
    var name = identifier();
    expect(KdlTerm.EQUALS);
    var val = value();
    return [name, val];
  }

  List<KdlNode> children() {
    expect(KdlTerm.LBRACE);
    var nodes = nodeList();
    linespaceStar();
    expect(KdlTerm.RBRACE);
    return nodes;
  }

  KdlValue value() {
    var ty = type();
    var t = tokenizer.nextToken();
    var v = valueWithoutType(t);
    if (ty == null) {
      return v;
    } else {
      return v.asType(ty, typeParsers[ty]);
    }
  }

  KdlValue valueWithoutType(KdlToken t) {
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
        throw ex("Expected value, got ${t.type}", t);
    }
  }

  String? type() {
    if (tokenizer.peekToken().type != KdlTerm.LPAREN) return null;
    expect(KdlTerm.LPAREN);
    wsStar();
    var ty = identifier();
    wsStar();
    expect(KdlTerm.RPAREN);
    wsStar();
    return ty;
  }

  void slashdash() {
    var t = tokenizer.nextToken();
    if (t.type != KdlTerm.SLASHDASH) {
      throw ex("Expected SLASHDASH, found ${t.type}", t);
    }
    linespaceStar();
    var peek = tokenizer.peekToken();
    switch (peek.type) {
      case KdlTerm.RBRACE:
      case KdlTerm.EOF:
      case KdlTerm.SEMICOLON:
        throw ex("Unexpected ${peek.type} after SLASHDASH", peek);
      default:
        break;
    }
  }

  expect(KdlTerm type) {
    var t = tokenizer.peekToken();
    if (t.type == type) {
      return tokenizer.nextToken().value;
    } else {
      throw ex("Expected ${type}, got ${t.type}", t);
    }
  }

  void expectEndOfFile() {
    var t = tokenizer.peekToken();
    if (t.type == KdlTerm.EOF) return;

    throw ex("Expected EOF, got ${t.type}", t);
  }

  KdlParseException ex(String message, [KdlToken? token = null]) {
    token = token ?? tokenizer.peekToken();
    return KdlParseException(message, token.line, token.column);
  }
}
