import 'package:test/test.dart';
import 'package:big_decimal/big_decimal.dart';

import 'package:kdl/src/tokenizer.dart';

void main() {
  test('peek and peek after next', () {
    var tokenizer = KdlV1Tokenizer("node 1 2 3");

    expect(tokenizer.peekToken(), equals(KdlToken(KdlTerm.ident, "node")));
    expect(tokenizer.peekTokenAfterNext(), equals(KdlToken(KdlTerm.whitespace, " ")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, "node")));
    expect(tokenizer.peekToken(), equals(KdlToken(KdlTerm.whitespace, " ")));
    expect(tokenizer.peekTokenAfterNext(), equals(KdlToken(KdlTerm.integer, 1)));
  });

  test('identifier', () {
    expect(KdlV1Tokenizer("foo").nextToken(), equals(KdlToken(KdlTerm.ident, "foo")));
    expect(KdlV1Tokenizer("foo-bar123").nextToken(), equals(KdlToken(KdlTerm.ident, "foo-bar123")));
  });

  test('string', () {
    expect(KdlV1Tokenizer('"foo"').nextToken(), equals(KdlToken(KdlTerm.string, "foo")));
    expect(KdlV1Tokenizer(r'"foo\nbar"').nextToken(), equals(KdlToken(KdlTerm.string, "foo\nbar")));
    expect(KdlV1Tokenizer(r'"\u{10FFF}"').nextToken(), equals(KdlToken(KdlTerm.string, "\u{10FFF}")));
  });

  test('rawstring', () {
    expect(KdlV1Tokenizer('r"foo\\nbar"').nextToken(), equals(KdlToken(KdlTerm.rawstring, "foo\\nbar")));
    expect(KdlV1Tokenizer('r#"foo"bar"#').nextToken(), equals(KdlToken(KdlTerm.rawstring, "foo\"bar")));
    expect(KdlV1Tokenizer('r##"foo"#bar"##').nextToken(), equals(KdlToken(KdlTerm.rawstring, "foo\"#bar")));
    expect(KdlV1Tokenizer('r#""foo""#').nextToken(), equals(KdlToken(KdlTerm.rawstring, "\"foo\"")));

    var tokenizer = KdlV1Tokenizer('node r"C:\\Users\\zkat\\"');
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, "node")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, " ")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rawstring, "C:\\Users\\zkat\\")));

    tokenizer = KdlV1Tokenizer('other-node r#"hello"world"#');
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, "other-node")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, " ")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rawstring, "hello\"world")));
  });

  test('integer', () {
    expect(KdlV1Tokenizer("123").nextToken(), equals(KdlToken(KdlTerm.integer, 123)));
    expect(KdlV1Tokenizer("0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.integer, 0x0123456789abcdef)));
    expect(KdlV1Tokenizer("0o01234567").nextToken(), equals(KdlToken(KdlTerm.integer, 342391)));
    expect(KdlV1Tokenizer("0b101001").nextToken(), equals(KdlToken(KdlTerm.integer, 41)));
    expect(KdlV1Tokenizer("-0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.integer, -0x0123456789abcdef)));
    expect(KdlV1Tokenizer("-0o01234567").nextToken(), equals(KdlToken(KdlTerm.integer, -342391)));
    expect(KdlV1Tokenizer("-0b101001").nextToken(), equals(KdlToken(KdlTerm.integer, -41)));
    expect(KdlV1Tokenizer("+0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.integer, 0x0123456789abcdef)));
    expect(KdlV1Tokenizer("+0o01234567").nextToken(), equals(KdlToken(KdlTerm.integer, 342391)));
    expect(KdlV1Tokenizer("+0b101001").nextToken(), equals(KdlToken(KdlTerm.integer, 41)));
  });

  test('float', () {
    expect(KdlV1Tokenizer("1.23").nextToken(), equals(KdlToken(KdlTerm.decimal, BigDecimal.parse('1.23'))));
  });

  test('boolean', () {
    expect(KdlV1Tokenizer("true").nextToken(), equals(KdlToken(KdlTerm.trueKeyword, true)));
    expect(KdlV1Tokenizer("false").nextToken(), equals(KdlToken(KdlTerm.falseKeyword, false)));
  });

  test('null', () {
    expect(KdlV1Tokenizer("null").nextToken(), equals(KdlToken(KdlTerm.nullKeyword, null)));
  });

  test('symbols', () {
    expect(KdlV1Tokenizer("{").nextToken(), equals(KdlToken(KdlTerm.lbrace, '{')));
    expect(KdlV1Tokenizer("}").nextToken(), equals(KdlToken(KdlTerm.rbrace, '}')));
    expect(KdlV1Tokenizer("=").nextToken(), equals(KdlToken(KdlTerm.equals, '=')));
  });

  test('whitespace', () {
    expect(KdlV1Tokenizer(" ").nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(KdlV1Tokenizer("\t").nextToken(), equals(KdlToken(KdlTerm.whitespace, "\t")));
    expect(KdlV1Tokenizer("    \t").nextToken(), equals(KdlToken(KdlTerm.whitespace, "    \t")));
    expect(KdlV1Tokenizer("\\\n").nextToken(), equals(KdlToken(KdlTerm.whitespace, "\\\n")));
    expect(KdlV1Tokenizer("\\").nextToken(), equals(KdlToken(KdlTerm.whitespace, "\\")));
    expect(KdlV1Tokenizer("\\//some comment\n").nextToken(), equals(KdlToken(KdlTerm.whitespace, "\\\n")));
    expect(KdlV1Tokenizer("\\ //some comment\n").nextToken(), equals(KdlToken(KdlTerm.whitespace, "\\ \n")));
    expect(KdlV1Tokenizer("\\//some comment").nextToken(), equals(KdlToken(KdlTerm.whitespace, "\\")));
  });

  test('multiple_tokens', () {
    var tokenizer = KdlV1Tokenizer("node 1 \"two\" a=3");

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.integer, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.string, 'two')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'a')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.equals, '=')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.integer, 3)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null)));
  });

  test('single_line_comment', () {
    expect(KdlV1Tokenizer("// comment").nextToken(), equals(KdlToken(KdlTerm.eof, '')));

    var tokenizer = KdlV1Tokenizer("""
node1
// comment
node2
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node1')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node2')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null)));
  });

  test('multiline_comment', () {
    var tokenizer = KdlV1Tokenizer("foo /*bar=1*/ baz=2");

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, '  ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'baz')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.equals, '=')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.integer, 2)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null)));
  });

  test('utf8', () {
    expect(KdlV1Tokenizer("😁").nextToken(), equals(KdlToken(KdlTerm.ident, '😁')));
    expect(KdlV1Tokenizer('"😁"').nextToken(), equals(KdlToken(KdlTerm.string, '😁')));
    expect(KdlV1Tokenizer('ノード').nextToken(), equals(KdlToken(KdlTerm.ident, 'ノード')));
    expect(KdlV1Tokenizer('お名前').nextToken(), equals(KdlToken(KdlTerm.ident, 'お名前')));
    expect(KdlV1Tokenizer('"☜(ﾟヮﾟ☜)"').nextToken(), equals(KdlToken(KdlTerm.string, '☜(ﾟヮﾟ☜)')));

    var tokenizer = KdlV1Tokenizer("""
smile "😁"
ノード お名前="☜(ﾟヮﾟ☜)"
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'smile')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.string, '😁')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'ノード')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'お名前')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.equals, '=')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.string, '☜(ﾟヮﾟ☜)')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null)));
  });

  test('semicolon', () {
    var tokenizer = KdlV1Tokenizer('node1; node2');

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node1')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.semicolon, ';')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node2')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null)));
  });

  test('slash_dash', () {
    var tokenizer = KdlV1Tokenizer("""
/-mynode /-"foo" /-key=1 /-{
  a
}
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.slashdash, '/-')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'mynode')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.slashdash, '/-')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.string, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.slashdash, '/-')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'key')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.equals, '=')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.integer, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.slashdash, '/-')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.lbrace, '{')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, '  ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'a')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rbrace, '}')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null)));
  });

  test('multiline_nodes', () {
    var tokenizer = KdlV1Tokenizer("""
title \\
  "Some title"
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'title')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' \\\n  ')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.string, 'Some title')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null)));
  });

  test('types', () {
    var tokenizer = KdlV1Tokenizer("(foo)bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.lparen, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rparen, ')')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'bar')));

    tokenizer = KdlV1Tokenizer("(foo)/*asdf*/bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.lparen, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rparen, ')')));
    expect(() => tokenizer.nextToken(), throwsA(anything));

    tokenizer = KdlV1Tokenizer("(foo/*asdf*/)bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.lparen, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'foo')));
    expect(() => tokenizer.nextToken(), throwsA(anything));
  });
}
