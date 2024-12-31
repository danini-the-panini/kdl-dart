import 'package:kdl/src/document.dart';
import 'package:kdl/src/parser.dart';
import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/v1/tokenizer.dart';

class KdlV1Parser extends KdlParser {
  int parserVersion = 1;

  @override
  KdlTokenizer createTokenizer(String string) {
    return KdlV1Tokenizer(string);
  }

  @override
  void argsPropsChildren(KdlNode node) {
    var commented = false;
    while (true) {
      wsStar();
      switch (tokenizer.peekToken().type) {
      case KdlTerm.IDENT:
        var p = prop();
        if (!commented) {
          node.properties[p[0]] = p[1];
        }
        commented = false;
        break;
      case KdlTerm.LBRACE:
        var childNodes = children();
        if (!commented) {
          node.children = childNodes;
        }
        _expectNodeTerm();
        return;
      case KdlTerm.SLASHDASH:
        commented = true;
        tokenizer.nextToken();
        wsStar();
        break;
      case KdlTerm.NEWLINE:
      case KdlTerm.EOF:
      case KdlTerm.SEMICOLON:
        tokenizer.nextToken();
        return;
      case KdlTerm.STRING:
        var t = tokenizer.peekTokenAfterNext();
        if (t.type == KdlTerm.EQUALS) {
          var p = prop();
          if (!commented) {
            node.properties[p[0]] = p[1];
          }
        } else {
          var v = value();
          if (!commented) {
            node.arguments.add(v);
          }
        }
        commented = false;
        break;
      default:
        var v = value();
        if (!commented) {
          node.arguments.add(v);
        }
        commented = false;
        break;
      }
    }
  }

  @override
  KdlValue valueWithoutType(KdlToken t) {
    switch (t.type) {
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

  @override
  String? type() {
    if (tokenizer.peekToken().type != KdlTerm.LPAREN) return null;
    expect(KdlTerm.LPAREN);
    var ty = identifier();
    expect(KdlTerm.RPAREN);
    return ty;
  }

  _expectNodeTerm() {
    wsStar();
    var t = tokenizer.peekToken().type;
    if (t == KdlTerm.NEWLINE || t == KdlTerm.SEMICOLON || t == KdlTerm.EOF) {
      tokenizer.nextToken();
    } else {
      throw "Unexpected ${t}";
    }
  }
}
