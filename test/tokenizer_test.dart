import 'package:test/test.dart';
import 'package:big_decimal/big_decimal.dart';

import '../lib/src/tokenizer.dart';

void main() {
  test('peek and peek after next', () {
    var tokenizer = KdlTokenizer("node 1 2 3");

    expect(tokenizer.peekToken(), equals(KdlToken(KdlTerm.IDENT, "node")));
    expect(tokenizer.peekTokenAfterNext(), equals(KdlToken(KdlTerm.WS, " ")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, "node")));
    expect(tokenizer.peekToken(), equals(KdlToken(KdlTerm.WS, " ")));
    expect(tokenizer.peekTokenAfterNext(), equals(KdlToken(KdlTerm.INTEGER, 1)));
  });

  test('identifier', () {
    expect(KdlTokenizer("foo").nextToken(), equals(KdlToken(KdlTerm.IDENT, "foo")));
    expect(KdlTokenizer("foo-bar123").nextToken(), equals(KdlToken(KdlTerm.IDENT, "foo-bar123")));
    expect(KdlTokenizer("-").nextToken(), equals(KdlToken(KdlTerm.IDENT, "-")));
    expect(KdlTokenizer("--").nextToken(), equals(KdlToken(KdlTerm.IDENT, "--")));
  });

  test('string', () {
    expect(KdlTokenizer('"foo"').nextToken(), equals(KdlToken(KdlTerm.STRING, "foo")));
    expect(KdlTokenizer(r'"foo\nbar"').nextToken(), equals(KdlToken(KdlTerm.STRING, "foo\nbar")));
    expect(KdlTokenizer(r'"\u{10FFF}"').nextToken(), equals(KdlToken(KdlTerm.STRING, "\u{10FFF}")));
    expect(KdlTokenizer('"\\\n\n\nfoo"').nextToken(), equals(KdlToken(KdlTerm.STRING, "foo")));
  });

  test('rawstring', () {
    expect(KdlTokenizer('#"foo\\nbar"#').nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "foo\\nbar")));
    expect(KdlTokenizer('#"foo"bar"#').nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "foo\"bar")));
    expect(KdlTokenizer('##"foo"#bar"##').nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "foo\"#bar")));
    expect(KdlTokenizer('#""foo""#').nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "\"foo\"")));

    var tokenizer = KdlTokenizer('node #"C:\\Users\\zkat\\"#');
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, "node")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, " ", 1, 5)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "C:\\Users\\zkat\\", 1, 6)));

    tokenizer = KdlTokenizer('other-node #"hello"world"#');
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, "other-node")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, " ", 1, 11)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RAWSTRING, "hello\"world", 1, 12)));
  });

  test('integer', () {
    expect(KdlTokenizer("123").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 123)));
    expect(KdlTokenizer("0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 0x0123456789abcdef)));
    expect(KdlTokenizer("0o01234567").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 342391)));
    expect(KdlTokenizer("0b101001").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 41)));
    expect(KdlTokenizer("-0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.INTEGER, -0x0123456789abcdef)));
    expect(KdlTokenizer("-0o01234567").nextToken(), equals(KdlToken(KdlTerm.INTEGER, -342391)));
    expect(KdlTokenizer("-0b101001").nextToken(), equals(KdlToken(KdlTerm.INTEGER, -41)));
    expect(KdlTokenizer("+0x0123456789abcdef").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 0x0123456789abcdef)));
    expect(KdlTokenizer("+0o01234567").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 342391)));
    expect(KdlTokenizer("+0b101001").nextToken(), equals(KdlToken(KdlTerm.INTEGER, 41)));
  });

  test('float', () {
    expect(KdlTokenizer("1.23").nextToken(), equals(KdlToken(KdlTerm.DECIMAL, BigDecimal.parse('1.23'))));
    expect(KdlTokenizer("#inf").nextToken(), equals(KdlToken(KdlTerm.DOUBLE, double.infinity)));
    expect(KdlTokenizer("#-inf").nextToken(), equals(KdlToken(KdlTerm.DOUBLE, -double.infinity)));
    var nan = KdlTokenizer("#nan").nextToken();
    expect(nan.type, equals(KdlTerm.DOUBLE));
    expect(nan.value, isNaN);
  });

  test('boolean', () {
    expect(KdlTokenizer("#true").nextToken(), equals(KdlToken(KdlTerm.TRUE, true)));
    expect(KdlTokenizer("#false").nextToken(), equals(KdlToken(KdlTerm.FALSE, false)));
  });

  test('null', () {
    expect(KdlTokenizer("#null").nextToken(), equals(KdlToken(KdlTerm.NULL, null)));
  });

  test('symbols', () {
    expect(KdlTokenizer("{").nextToken(), equals(KdlToken(KdlTerm.LBRACE, '{')));
    expect(KdlTokenizer("}").nextToken(), equals(KdlToken(KdlTerm.RBRACE, '}')));
  });

  test('equals', () {
    expect(KdlTokenizer("=").nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=')));
    expect(KdlTokenizer(" =").nextToken(), equals(KdlToken(KdlTerm.EQUALS, ' =')));
    expect(KdlTokenizer("= ").nextToken(), equals(KdlToken(KdlTerm.EQUALS, '= ')));
    expect(KdlTokenizer(" = ").nextToken(), equals(KdlToken(KdlTerm.EQUALS, ' = ')));
    expect(KdlTokenizer(" =foo").nextToken(), equals(KdlToken(KdlTerm.EQUALS, ' =')));
  });

  test('whitespace', () {
    expect(KdlTokenizer(" ").nextToken(), equals(KdlToken(KdlTerm.WS, ' ')));
    expect(KdlTokenizer("\t").nextToken(), equals(KdlToken(KdlTerm.WS, "\t")));
    expect(KdlTokenizer("    \t").nextToken(), equals(KdlToken(KdlTerm.WS, "    \t")));
    expect(KdlTokenizer("\\\n").nextToken(), equals(KdlToken(KdlTerm.WS, "\\\n")));
    expect(KdlTokenizer("\\").nextToken(), equals(KdlToken(KdlTerm.WS, "\\")));
    expect(KdlTokenizer("\\//some comment\n").nextToken(), equals(KdlToken(KdlTerm.WS, "\\\n")));
    expect(KdlTokenizer("\\ //some comment\n").nextToken(), equals(KdlToken(KdlTerm.WS, "\\ \n")));
    expect(KdlTokenizer("\\//some comment").nextToken(), equals(KdlToken(KdlTerm.WS, "\\")));
    expect(KdlTokenizer(" \\\n").nextToken(), equals(KdlToken(KdlTerm.WS, " \\\n")));
    expect(KdlTokenizer(" \\//some comment\n").nextToken(), equals(KdlToken(KdlTerm.WS, " \\\n")));
    expect(KdlTokenizer(" \\ //some comment\n").nextToken(), equals(KdlToken(KdlTerm.WS, " \\ \n")));
    expect(KdlTokenizer(" \\//some comment").nextToken(), equals(KdlToken(KdlTerm.WS, " \\")));
    expect(KdlTokenizer(" \\\n  \\\n  ").nextToken(), equals(KdlToken(KdlTerm.WS, " \\\n  \\\n  ")));
  });

  test('multiple_tokens', () {
    var tokenizer = KdlTokenizer("node 1 \"two\" a=3");

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node', 1, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 1, 5)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.INTEGER, 1, 1, 6)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 1, 7)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, 'two', 1, 8)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 1, 13)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'a', 1, 14)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=', 1, 15)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.INTEGER, 3, 1, 16)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '', 1, 17)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null, 1, 17)));
  });

  test('single_line_comment', () {
    expect(KdlTokenizer("// comment").nextToken(), equals(KdlToken(KdlTerm.EOF, '')));

    var tokenizer = KdlTokenizer("""
node1
// comment
node2
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node1', 1, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n", 1, 6)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n", 2, 11)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node2', 3, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '', 3, 6)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null, 3, 6)));
  });

  test('multiline_comment', () {
    var tokenizer = KdlTokenizer("foo /*bar=1*/ baz=2");

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'foo', 1, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, '  ', 1, 4)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'baz', 1, 15)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=', 1, 18)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.INTEGER, 2, 1, 19)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '', 1, 20)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null, 1, 20)));
  });

  test('utf8', () {
    expect(KdlTokenizer("😁").nextToken(), equals(KdlToken(KdlTerm.IDENT, '😁')));
    expect(KdlTokenizer('"😁"').nextToken(), equals(KdlToken(KdlTerm.STRING, '😁')));
    expect(KdlTokenizer('ノード').nextToken(), equals(KdlToken(KdlTerm.IDENT, 'ノード')));
    expect(KdlTokenizer('お名前').nextToken(), equals(KdlToken(KdlTerm.IDENT, 'お名前')));
    expect(KdlTokenizer('"☜(ﾟヮﾟ☜)"').nextToken(), equals(KdlToken(KdlTerm.STRING, '☜(ﾟヮﾟ☜)')));

    var tokenizer = KdlTokenizer("""
smile "😁"
ノード お名前="☜(ﾟヮﾟ☜)"
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'smile', 1, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 1, 6)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, '😁', 1, 7)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n", 1, 10)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'ノード', 2, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 2, 4)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'お名前', 2, 5)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=', 2, 8)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, '☜(ﾟヮﾟ☜)', 2, 9)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '', 2, 18)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null, 2, 18)));
  });

  test('semicolon', () {
    var tokenizer = KdlTokenizer('node1; node2');

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node1', 1, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SEMICOLON, ';', 1, 6)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 1, 7)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'node2', 1, 8)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '', 1, 13)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null, 1, 13)));
  });

  test('slash_dash', () {
    var tokenizer = KdlTokenizer("""
/-mynode /-"foo" /-key=1 /-{
  a
}
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SLASHDASH, '/-', 1, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'mynode', 1, 3)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 1, 9)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SLASHDASH, '/-', 1, 10)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, 'foo', 1, 12)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 1, 17)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SLASHDASH, '/-', 1, 18)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'key', 1, 20)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EQUALS, '=', 1, 23)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.INTEGER, 1, 1, 24)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, ' ', 1, 25)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.SLASHDASH, '/-', 1, 26)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.LBRACE, '{', 1, 28)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n", 1, 29)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, '  ', 2, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'a', 2, 3)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.NEWLINE, "\n", 2, 4)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RBRACE, '}', 3, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '', 3, 2)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null, 3, 2)));
  });

  test('multiline_nodes', () {
    var tokenizer = KdlTokenizer("""
title \\
  "Some title"
    """.trim());

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'title', 1, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.WS, " \\\n  ", 1, 6)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.STRING, 'Some title', 2, 3)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, '', 2, 15)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.EOF, null, 2, 15)));
  });

  test('types', () {
    var tokenizer = KdlTokenizer("(foo)bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.LPAREN, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RPAREN, ')')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'bar')));

    tokenizer = KdlTokenizer("(foo)/*asdf*/bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.LPAREN, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RPAREN, ')')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'bar')));

    tokenizer = KdlTokenizer("(foo/*asdf*/)bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.LPAREN, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.RPAREN, ')')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.IDENT, 'bar')));
  });
}
