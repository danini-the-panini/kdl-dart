import 'package:kdl/src/document.dart';
import 'package:kdl/src/parser.dart';
import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/v1/tokenizer.dart';

class KdlV1Parser extends KdlParser {
  @override
  int get parserVersion => 1;

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
      case KdlTerm.ident:
        var p = prop();
        if (!commented) {
          node.properties[p[0]] = p[1];
        }
        commented = false;
        break;
      case KdlTerm.lbrace:
        var childNodes = children();
        if (!commented) {
          node.children = childNodes;
        }
        _expectNodeTerm();
        return;
      case KdlTerm.slashdash:
        commented = true;
        tokenizer.nextToken();
        wsStar();
        break;
      case KdlTerm.newline:
      case KdlTerm.eof:
      case KdlTerm.semicolon:
        tokenizer.nextToken();
        return;
      case KdlTerm.string:
        var t = tokenizer.peekTokenAfterNext();
        if (t.type == KdlTerm.equals) {
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

  @override
  String? type() {
    if (tokenizer.peekToken().type != KdlTerm.lparen) return null;
    expect(KdlTerm.lparen);
    var ty = identifier();
    expect(KdlTerm.rparen);
    return ty;
  }

  _expectNodeTerm() {
    wsStar();
    var t = tokenizer.peekToken().type;
    if (t == KdlTerm.newline || t == KdlTerm.semicolon || t == KdlTerm.eof) {
      tokenizer.nextToken();
    } else {
      throw "Unexpected $t";
    }
  }
}
