import 'package:test/test.dart';
import 'package:big_decimal/big_decimal.dart';

import '../lib/src/tokenizer.dart';

void main() {
  test('peek and peek after next', () {
    var tokenizer = KdlTokenizer("node 1 2 3");

    expect(tokenizer.peekToken(), equals([KdlToken.IDENT, "node"]));
    expect(tokenizer.peekTokenAfterNext(), equals([KdlToken.WS, " "]));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, "node"]));
    expect(tokenizer.peekToken(), equals([KdlToken.WS, " "]));
    expect(tokenizer.peekTokenAfterNext(), equals([KdlToken.INTEGER, 1]));
  });

  test('identifier', () {
    expect(KdlTokenizer("foo").nextToken(), equals([KdlToken.IDENT, "foo"]));
    expect(KdlTokenizer("foo-bar123").nextToken(), equals([KdlToken.IDENT, "foo-bar123"]));
    expect(KdlTokenizer("-").nextToken(), equals([KdlToken.IDENT, "-"]));
    expect(KdlTokenizer("--").nextToken(), equals([KdlToken.IDENT, "--"]));
  });

  test('string', () {
    expect(KdlTokenizer('"foo"').nextToken(), equals([KdlToken.STRING, "foo"]));
    expect(KdlTokenizer(r'"foo\nbar"').nextToken(), equals([KdlToken.STRING, "foo\nbar"]));
    expect(KdlTokenizer(r'"\u{10FFF}"').nextToken(), equals([KdlToken.STRING, "\u{10FFF}"]));
    expect(KdlTokenizer('"\\\n\n\nfoo"').nextToken(), equals([KdlToken.STRING, "foo"]));
  });

  test('rawstring', () {
    expect(KdlTokenizer('#"foo\\nbar"#').nextToken(), equals([KdlToken.RAWSTRING, "foo\\nbar"]));
    expect(KdlTokenizer('#"foo"bar"#').nextToken(), equals([KdlToken.RAWSTRING, "foo\"bar"]));
    expect(KdlTokenizer('##"foo"#bar"##').nextToken(), equals([KdlToken.RAWSTRING, "foo\"#bar"]));
    expect(KdlTokenizer('#""foo""#').nextToken(), equals([KdlToken.RAWSTRING, "\"foo\""]));

    var tokenizer = KdlTokenizer('node #"C:\\Users\\zkat\\"#');
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, "node"]));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, " "]));
    expect(tokenizer.nextToken(), equals([KdlToken.RAWSTRING, "C:\\Users\\zkat\\"]));

    tokenizer = KdlTokenizer('other-node #"hello"world"#');
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, "other-node"]));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, " "]));
    expect(tokenizer.nextToken(), equals([KdlToken.RAWSTRING, "hello\"world"]));
  });

  test('integer', () {
    expect(KdlTokenizer("123").nextToken(), equals([KdlToken.INTEGER, 123]));
    expect(KdlTokenizer("0x0123456789abcdef").nextToken(), equals([KdlToken.INTEGER, 0x0123456789abcdef]));
    expect(KdlTokenizer("0o01234567").nextToken(), equals([KdlToken.INTEGER, 342391]));
    expect(KdlTokenizer("0b101001").nextToken(), equals([KdlToken.INTEGER, 41]));
    expect(KdlTokenizer("-0x0123456789abcdef").nextToken(), equals([KdlToken.INTEGER, -0x0123456789abcdef]));
    expect(KdlTokenizer("-0o01234567").nextToken(), equals([KdlToken.INTEGER, -342391]));
    expect(KdlTokenizer("-0b101001").nextToken(), equals([KdlToken.INTEGER, -41]));
    expect(KdlTokenizer("+0x0123456789abcdef").nextToken(), equals([KdlToken.INTEGER, 0x0123456789abcdef]));
    expect(KdlTokenizer("+0o01234567").nextToken(), equals([KdlToken.INTEGER, 342391]));
    expect(KdlTokenizer("+0b101001").nextToken(), equals([KdlToken.INTEGER, 41]));
  });

  test('float', () {
    expect(KdlTokenizer("1.23").nextToken(), equals([KdlToken.DECIMAL, BigDecimal.parse('1.23')]));
    expect(KdlTokenizer("#inf").nextToken(), equals([KdlToken.DOUBLE, double.infinity]));
    expect(KdlTokenizer("#-inf").nextToken(), equals([KdlToken.DOUBLE, -double.infinity]));
    var nan = KdlTokenizer("#nan").nextToken();
    expect(nan[0], equals(KdlToken.DOUBLE));
    expect(nan[1], isNaN);
  });

  test('boolean', () {
    expect(KdlTokenizer("#true").nextToken(), equals([KdlToken.TRUE, true]));
    expect(KdlTokenizer("#false").nextToken(), equals([KdlToken.FALSE, false]));
  });

  test('null', () {
    expect(KdlTokenizer("#null").nextToken(), equals([KdlToken.NULL, null]));
  });

  test('symbols', () {
    expect(KdlTokenizer("{").nextToken(), equals([KdlToken.LBRACE, '{']));
    expect(KdlTokenizer("}").nextToken(), equals([KdlToken.RBRACE, '}']));
  });

  test('equals', () {
    expect(KdlTokenizer("=").nextToken(), equals([KdlToken.EQUALS, '=']));
    expect(KdlTokenizer(" =").nextToken(), equals([KdlToken.EQUALS, ' =']));
    expect(KdlTokenizer("= ").nextToken(), equals([KdlToken.EQUALS, '= ']));
    expect(KdlTokenizer(" = ").nextToken(), equals([KdlToken.EQUALS, ' = ']));
    expect(KdlTokenizer(" =foo").nextToken(), equals([KdlToken.EQUALS, ' =']));
  });

  test('whitespace', () {
    expect(KdlTokenizer(" ").nextToken(), equals([KdlToken.WS, ' ']));
    expect(KdlTokenizer("\t").nextToken(), equals([KdlToken.WS, "\t"]));
    expect(KdlTokenizer("    \t").nextToken(), equals([KdlToken.WS, "    \t"]));
    expect(KdlTokenizer("\\\n").nextToken(), equals([KdlToken.WS, "\\\n"]));
    expect(KdlTokenizer("\\").nextToken(), equals([KdlToken.WS, "\\"]));
    expect(KdlTokenizer("\\//some comment\n").nextToken(), equals([KdlToken.WS, "\\\n"]));
    expect(KdlTokenizer("\\ //some comment\n").nextToken(), equals([KdlToken.WS, "\\ \n"]));
    expect(KdlTokenizer("\\//some comment").nextToken(), equals([KdlToken.WS, "\\"]));
    expect(KdlTokenizer(" \\\n").nextToken(), equals([KdlToken.WS, " \\\n"]));
    expect(KdlTokenizer(" \\//some comment\n").nextToken(), equals([KdlToken.WS, " \\\n"]));
    expect(KdlTokenizer(" \\ //some comment\n").nextToken(), equals([KdlToken.WS, " \\ \n"]));
    expect(KdlTokenizer(" \\//some comment").nextToken(), equals([KdlToken.WS, " \\"]));
    expect(KdlTokenizer(" \\\n  \\\n  ").nextToken(), equals([KdlToken.WS, " \\\n  \\\n  "]));
  });

  test('multiple_tokens', () {
    var tokenizer = KdlTokenizer("node 1 \"two\" a=3");

    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'node']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.INTEGER, 1]));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.STRING, 'two']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'a']));
    expect(tokenizer.nextToken(), equals([KdlToken.EQUALS, '=']));
    expect(tokenizer.nextToken(), equals([KdlToken.INTEGER, 3]));
    expect(tokenizer.nextToken(), equals([KdlToken.EOF, '']));
    expect(tokenizer.nextToken(), equals([false, false]));
  });

  test('single_line_comment', () {
    expect(KdlTokenizer("// comment").nextToken(), equals([KdlToken.EOF, '']));

    var tokenizer = KdlTokenizer("""
node1
// comment
node2
    """.trim());

    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'node1']));
    expect(tokenizer.nextToken(), equals([KdlToken.NEWLINE, "\n"]));
    expect(tokenizer.nextToken(), equals([KdlToken.NEWLINE, "\n"]));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'node2']));
    expect(tokenizer.nextToken(), equals([KdlToken.EOF, '']));
    expect(tokenizer.nextToken(), equals([false, false]));
  });

  test('multiline_comment', () {
    var tokenizer = KdlTokenizer("foo /*bar=1*/ baz=2");

    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'foo']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, '  ']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'baz']));
    expect(tokenizer.nextToken(), equals([KdlToken.EQUALS, '=']));
    expect(tokenizer.nextToken(), equals([KdlToken.INTEGER, 2]));
    expect(tokenizer.nextToken(), equals([KdlToken.EOF, '']));
    expect(tokenizer.nextToken(), equals([false, false]));
  });

  test('utf8', () {
    expect(KdlTokenizer("😁").nextToken(), equals([KdlToken.IDENT, '😁']));
    expect(KdlTokenizer('"😁"').nextToken(), equals([KdlToken.STRING, '😁']));
    expect(KdlTokenizer('ノード').nextToken(), equals([KdlToken.IDENT, 'ノード']));
    expect(KdlTokenizer('お名前').nextToken(), equals([KdlToken.IDENT, 'お名前']));
    expect(KdlTokenizer('"☜(ﾟヮﾟ☜)"').nextToken(), equals([KdlToken.STRING, '☜(ﾟヮﾟ☜)']));

    var tokenizer = KdlTokenizer("""
smile "😁"
ノード お名前="☜(ﾟヮﾟ☜)"
    """.trim());

    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'smile']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.STRING, '😁']));
    expect(tokenizer.nextToken(), equals([KdlToken.NEWLINE, "\n"]));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'ノード']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'お名前']));
    expect(tokenizer.nextToken(), equals([KdlToken.EQUALS, '=']));
    expect(tokenizer.nextToken(), equals([KdlToken.STRING, '☜(ﾟヮﾟ☜)']));
    expect(tokenizer.nextToken(), equals([KdlToken.EOF, '']));
    expect(tokenizer.nextToken(), equals([false, false]));
  });

  test('semicolon', () {
    var tokenizer = KdlTokenizer('node1; node2');

    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'node1']));
    expect(tokenizer.nextToken(), equals([KdlToken.SEMICOLON, ';']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'node2']));
    expect(tokenizer.nextToken(), equals([KdlToken.EOF, '']));
    expect(tokenizer.nextToken(), equals([false, false]));
  });

  test('slash_dash', () {
    var tokenizer = KdlTokenizer("""
/-mynode /-"foo" /-key=1 /-{
  a
}
    """.trim());

    expect(tokenizer.nextToken(), equals([KdlToken.SLASHDASH, '/-']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'mynode']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.SLASHDASH, '/-']));
    expect(tokenizer.nextToken(), equals([KdlToken.STRING, 'foo']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.SLASHDASH, '/-']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'key']));
    expect(tokenizer.nextToken(), equals([KdlToken.EQUALS, '=']));
    expect(tokenizer.nextToken(), equals([KdlToken.INTEGER, 1]));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, ' ']));
    expect(tokenizer.nextToken(), equals([KdlToken.SLASHDASH, '/-']));
    expect(tokenizer.nextToken(), equals([KdlToken.LBRACE, '{']));
    expect(tokenizer.nextToken(), equals([KdlToken.NEWLINE, "\n"]));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, '  ']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'a']));
    expect(tokenizer.nextToken(), equals([KdlToken.NEWLINE, "\n"]));
    expect(tokenizer.nextToken(), equals([KdlToken.RBRACE, '}']));
    expect(tokenizer.nextToken(), equals([KdlToken.EOF, '']));
    expect(tokenizer.nextToken(), equals([false, false]));
  });

  test('multiline_nodes', () {
    var tokenizer = KdlTokenizer("""
title \\
  "Some title"
    """.trim());

    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'title']));
    expect(tokenizer.nextToken(), equals([KdlToken.WS, " \\\n  "]));
    expect(tokenizer.nextToken(), equals([KdlToken.STRING, 'Some title']));
    expect(tokenizer.nextToken(), equals([KdlToken.EOF, '']));
    expect(tokenizer.nextToken(), equals([false, false]));
  });

  test('types', () {
    var tokenizer = KdlTokenizer("(foo)bar");
    expect(tokenizer.nextToken(), equals([KdlToken.LPAREN, '(']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'foo']));
    expect(tokenizer.nextToken(), equals([KdlToken.RPAREN, ')']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'bar']));

    tokenizer = KdlTokenizer("(foo)/*asdf*/bar");
    expect(tokenizer.nextToken(), equals([KdlToken.LPAREN, '(']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'foo']));
    expect(tokenizer.nextToken(), equals([KdlToken.RPAREN, ')']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'bar']));

    tokenizer = KdlTokenizer("(foo/*asdf*/)bar");
    expect(tokenizer.nextToken(), equals([KdlToken.LPAREN, '(']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'foo']));
    expect(tokenizer.nextToken(), equals([KdlToken.RPAREN, ')']));
    expect(tokenizer.nextToken(), equals([KdlToken.IDENT, 'bar']));
  });
}
