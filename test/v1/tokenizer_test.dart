import 'package:test/test.dart';
import 'package:big_decimal/big_decimal.dart';

import 'package:kdl/src/tokenizer.dart';
import 'package:kdl/src/v1/tokenizer.dart';

void main() {
  test('peek and peek after next', () {
    var tokenizer = KdlV1Tokenizer("node 1 2 3");

    expect(tokenizer.peekToken(), equals(KdlToken(KdlTerm.IDENT, "node")));
    expect(tokenizer.peekTokenAfterNext(), equals(KdlToken(KdlTerm.WS, " ")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, "node")));
    expect(tokenizer.peekToken(), equals(KdlToken(KdlTerm.WS, " ")));
    expect(tokenizer.peekTokenAfterNext(), equals(KdlToken(KdlTerm.INTEGER, 1)));
  });

  test('identifier', () {
    expect(KdlV1Tokenizer("foo").nextToken(), equals(KdlToken(KdlTerm.IDENT, "foo")));
    expect(KdlV1Tokenizer("foo-bar123").nextToken(), equals(KdlToken(KdlTerm.IDENT, "foo-bar123")));
  });

  test('string', () {
    expect(KdlV1Tokenizer('"foo"').nextToken(), equals(KdlToken(KdlTerm.STRING, "foo")));
    expect(KdlV1Tokenizer(r'"foo\nbar"').nextToken(), equals(KdlToken(KdlTerm.STRING, "foo\nbar")));
    expect(KdlV1Tokenizer(r'"\u{10FFF}"').nextToken(), equals(KdlToken(KdlTerm.STRING, "\u{10FFF}")));
  });

  test('rawstring', () {
    expect(KdlV1Tokenizer('r"foo\\nbar"').nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "foo\\nbar")));
    expect(KdlV1Tokenizer('r#"foo"bar"#').nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "foo\"bar")));
    expect(KdlV1Tokenizer('r##"foo"#bar"##').nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "foo\"#bar")));
    expect(KdlV1Tokenizer('r#""foo""#').nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "\"foo\"")));

    var tokenizer = KdlV1Tokenizer('node r"C:\\Users\\zkat\\"');
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, "node")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, " ")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "C:\\Users\\zkat\\")));

    tokenizer = KdlV1Tokenizer('other-node r#"hello"world"#');
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, "other-node")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, " ")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "hello\"world")));
  });

  test('integer', () {
    expect(KdlV1Tokenizer("123").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 123)));
    expect(KdlV1Tokenizer("0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 0x0123456789abcdef)));
    expect(KdlV1Tokenizer("0o01234567").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 342391)));
    expect(KdlV1Tokenizer("0b101001").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 41)));
    expect(KdlV1Tokenizer("-0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.INTEGER, -0x0123456789abcdef)));
    expect(KdlV1Tokenizer("-0o01234567").nextToken(), equals(KdlToken(KdlTerm.INTEGER, -342391)));
    expect(KdlV1Tokenizer("-0b101001").nextToken(), equals(KdlToken(KdlTerm.INTEGER, -41)));
    expect(KdlV1Tokenizer("+0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 0x0123456789abcdef)));
    expect(KdlV1Tokenizer("+0o01234567").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 342391)));
    expect(KdlV1Tokenizer("+0b101001").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 41)));
  });

  test('float', () {
    expect(KdlV1Tokenizer("1.23").nextToken(), equals(KdlToken(KdlTerm.DECIMAL, BigDecimal.parse('1.23'))));
  });

  test('boolean', () {
    expect(KdlV1Tokenizer("true").nextToken(), equals(KdlToken(KdlTerm.TRUE, true)));
    expect(KdlV1Tokenizer("false").nextToken(), equals(KdlToken(KdlTerm.FALSE, false)));
  });

  test('null', () {
    expect(KdlV1Tokenizer("null").nextToken(), equals(KdlToken(KdlTerm.NULL, null)));
  });

  test('symbols', () {
    expect(KdlV1Tokenizer("{").nextToken(), equals(KdlToken(KdlTerm.LBRACE, '{')));
    expect(KdlV1Tokenizer("}").nextToken(), equals(KdlToken(KdlTerm.RBRACE, '}')));
    expect(KdlV1Tokenizer("=").nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=')));
  });

  test('whitespace', () {
    expect(KdlV1Tokenizer(" ").nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(KdlV1Tokenizer("\t").nextToken(), equals(KdlToken(KdlTerm.WS, "\t")));
    expect(KdlV1Tokenizer("    \t").nextToken(), equals(KdlToken(KdlTerm.WS, "    \t")));
    expect(KdlV1Tokenizer("\\\n").nextToken(), equals(KdlToken(KdlTerm.WS, "\\\n")));
    expect(KdlV1Tokenizer("\\").nextToken(), equals(KdlToken(KdlTerm.WS, "\\")));
    expect(KdlV1Tokenizer("\\//some comment\n").nextToken(), equals(KdlToken(KdlTerm.WS, "\\\n")));
    expect(KdlV1Tokenizer("\\ //some comment\n").nextToken(), equals(KdlToken(KdlTerm.WS, "\\ \n")));
    expect(KdlV1Tokenizer("\\//some comment").nextToken(), equals(KdlToken(KdlTerm.WS, "\\")));
  });

  test('multiple_tokens', () {
    var tokenizer = KdlV1Tokenizer("node 1 \"two\" a=3");

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.INTEGER, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, 'two')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'a')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.INTEGER, 3)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null)));
  });

  test('single_line_comment', () {
    expect(KdlV1Tokenizer("// comment").nextToken(), equals(KdlToken(KdlTerm.EOF, '')));

    var tokenizer = KdlV1Tokenizer("""
node1
// comment
node2
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node1')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node2')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null)));
  });

  test('multiline_comment', () {
    var tokenizer = KdlV1Tokenizer("foo /*bar=1*/ baz=2");

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, '  ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'baz')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.INTEGER, 2)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null)));
  });

  test('utf8', () {
    expect(KdlV1Tokenizer("😁").nextToken(), equals(KdlToken(KdlTerm.IDENT, '😁')));
    expect(KdlV1Tokenizer('"😁"').nextToken(), equals(KdlToken(KdlTerm.STRING, '😁')));
    expect(KdlV1Tokenizer('ノード').nextToken(), equals(KdlToken(KdlTerm.IDENT, 'ノード')));
    expect(KdlV1Tokenizer('お名前').nextToken(), equals(KdlToken(KdlTerm.IDENT, 'お名前')));
    expect(KdlV1Tokenizer('"☜(ﾟヮﾟ☜)"').nextToken(), equals(KdlToken(KdlTerm.STRING, '☜(ﾟヮﾟ☜)')));

    var tokenizer = KdlV1Tokenizer("""
smile "😁"
ノード お名前="☜(ﾟヮﾟ☜)"
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'smile')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, '😁')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'ノード')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'お名前')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, '☜(ﾟヮﾟ☜)')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null)));
  });

  test('semicolon', () {
    var tokenizer = KdlV1Tokenizer('node1; node2');

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node1')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SEMICOLON, ';')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node2')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null)));
  });

  test('slash_dash', () {
    var tokenizer = KdlV1Tokenizer("""
/-mynode /-"foo" /-key=1 /-{
  a
}
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SLASHDASH, '/-')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'mynode')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SLASHDASH, '/-')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SLASHDASH, '/-')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'key')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.INTEGER, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SLASHDASH, '/-')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.LBRACE, '{')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, '  ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'a')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RBRACE, '}')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null)));
  });

  test('multiline_nodes', () {
    var tokenizer = KdlV1Tokenizer("""
title \\
  "Some title"
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'title')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' \\\n  ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, 'Some title')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null)));
  });

  test('types', () {
    var tokenizer = KdlV1Tokenizer("(foo)bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.LPAREN, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RPAREN, ')')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'bar')));

    tokenizer = KdlV1Tokenizer("(foo)/*asdf*/bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.LPAREN, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RPAREN, ')')));
    expect(() => tokenizer.nextToken(), throwsA(anything));

    tokenizer = KdlV1Tokenizer("(foo/*asdf*/)bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.LPAREN, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'foo')));
    expect(() => tokenizer.nextToken(), throwsA(anything));
  });
}
