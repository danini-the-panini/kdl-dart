import 'package:kdl/src/document.dart';
import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/types.dart';
import 'package:kdl/src/exception.dart';

class KdlParser {
  late KdlTokenizer tokenizer;
  late Map<String, Function> typeParsers;
  int depth = 0;
  int get parserVersion => 2;

  KdlDocument parse(String string,
      {Map<String, Function> typeParsers = const {}, bool parseTypes = true}) {
    tokenizer = createTokenizer(string);
    _checkVersion();

    if (parseTypes) {
      this.typeParsers = {...KdlTypes.mapping, ...typeParsers};
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
    KdlNode? n;
    while (((n, _) = node()).$2 != false) {
      if (n != null) nodes.add(n);
    }
    return nodes;
  }

  (KdlNode?, bool) node() {
    linespaceStar();

    var commented = false;
    if (tokenizer.peekToken().type == KdlTerm.slashdash) {
      slashdash();
      commented = true;
    }

    KdlNode node;
    String? ty;
    try {
      ty = type();
      node = KdlNode(identifier());
    } catch (error) {
      if (ty != null) rethrow;
      return (null, false);
    }

    argsPropsChildren(node);

    if (commented) return (null, true);

    if (ty != null) {
      return (node.asType(ty, typeParsers[ty]), true);
    }
    return (node, true);
  }

  String identifier() {
    var t = tokenizer.peekToken();
    if (t.type == KdlTerm.ident ||
        t.type == KdlTerm.string ||
        t.type == KdlTerm.rawstring) {
      tokenizer.nextToken();
      return t.value;
    }
    throw ex("Expected identifier, got ${t.type}", t);
  }

  void wsStar() {
    var t = tokenizer.peekToken();
    while (t.type == KdlTerm.whitespace) {
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
    return (t.type == KdlTerm.newline || t.type == KdlTerm.whitespace);
  }

  void argsPropsChildren(KdlNode node) {
    var commented = false;
    var hasChildren = false;
    while (true) {
      var peek = tokenizer.peekToken();
      switch (peek.type) {
        case KdlTerm.whitespace:
          wsStar();
          peek = tokenizer.peekToken();
          if (peek.type == KdlTerm.slashdash) {
            slashdash();
            peek = tokenizer.peekToken();
            commented = true;
          }
          switch (peek.type) {
            case KdlTerm.string:
            case KdlTerm.ident:
              if (hasChildren) throw ex("Unexpected ${peek.type}", peek);
              var t = tokenizer.peekTokenAfterNext();
              if (t.type == KdlTerm.equals) {
                var p = prop();
                if (!commented) node.properties[p[0]] = p[1];
              } else {
                var v = value();
                if (!commented) node.arguments.add(v);
              }
              commented = false;
              break;
            case KdlTerm.newline:
            case KdlTerm.eof:
            case KdlTerm.semicolon:
              tokenizer.nextToken();
              return;
            case KdlTerm.lbrace:
              lbrace(node, commented);
              hasChildren = true;
              commented = false;
              break;
            case KdlTerm.rbrace:
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
        case KdlTerm.eof:
        case KdlTerm.semicolon:
        case KdlTerm.newline:
          tokenizer.nextToken();
          return;
        case KdlTerm.lbrace:
          lbrace(node, commented);
          hasChildren = true;
          commented = false;
          break;
        case KdlTerm.rbrace:
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
    expect(KdlTerm.equals);
    var val = value();
    return [name, val];
  }

  List<KdlNode> children() {
    expect(KdlTerm.lbrace);
    var nodes = nodeList();
    linespaceStar();
    expect(KdlTerm.rbrace);
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
        throw ex("Expected value, got ${t.type}", t);
    }
  }

  String? type() {
    if (tokenizer.peekToken().type != KdlTerm.lparen) return null;
    expect(KdlTerm.lparen);
    wsStar();
    var ty = identifier();
    wsStar();
    expect(KdlTerm.rparen);
    wsStar();
    return ty;
  }

  void slashdash() {
    var t = tokenizer.nextToken();
    if (t.type != KdlTerm.slashdash) {
      throw ex("Expected SLASHDASH, found ${t.type}", t);
    }
    linespaceStar();
    var peek = tokenizer.peekToken();
    switch (peek.type) {
      case KdlTerm.rbrace:
      case KdlTerm.eof:
      case KdlTerm.semicolon:
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
      throw ex("Expected $type, got ${t.type}", t);
    }
  }

  void expectEndOfFile() {
    var t = tokenizer.peekToken();
    if (t.type == KdlTerm.eof) return;

    throw ex("Expected EOF, got ${t.type}", t);
  }

  KdlParseException ex(String message, [KdlToken? token]) {
    token = token ?? tokenizer.peekToken();
    return KdlParseException(message, token.line, token.column);
  }
}
