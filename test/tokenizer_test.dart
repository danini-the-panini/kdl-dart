import 'package:test/test.dart';
import 'package:big_decimal/big_decimal.dart';

import 'package:kdl/src/tokenizer.dart';

void main() {
  test('peek and peek after next', () {
    var tokenizer = KdlTokenizer("node 1 2 3");

    expect(tokenizer.peekToken(), equals(KdlToken(KdlTerm.ident, "node")));
    expect(tokenizer.peekTokenAfterNext(),
        equals(KdlToken(KdlTerm.whitespace, " ")));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, "node")));
    expect(tokenizer.peekToken(), equals(KdlToken(KdlTerm.whitespace, " ")));
    expect(
        tokenizer.peekTokenAfterNext(), equals(KdlToken(KdlTerm.integer, 1)));
  });

  test('identifier', () {
    expect(KdlTokenizer("foo").nextToken(),
        equals(KdlToken(KdlTerm.ident, "foo")));
    expect(KdlTokenizer("foo-bar123").nextToken(),
        equals(KdlToken(KdlTerm.ident, "foo-bar123")));
    expect(KdlTokenizer("-").nextToken(), equals(KdlToken(KdlTerm.ident, "-")));
    expect(
        KdlTokenizer("--").nextToken(), equals(KdlToken(KdlTerm.ident, "--")));
  });

  test('string', () {
    expect(KdlTokenizer('"foo"').nextToken(),
        equals(KdlToken(KdlTerm.string, "foo")));
    expect(KdlTokenizer(r'"foo\nbar"').nextToken(),
        equals(KdlToken(KdlTerm.string, "foo\nbar")));
    expect(KdlTokenizer(r'"\u{10FFF}"').nextToken(),
        equals(KdlToken(KdlTerm.string, "\u{10FFF}")));
    expect(KdlTokenizer('"\\\n\n\nfoo"').nextToken(),
        equals(KdlToken(KdlTerm.string, "foo")));
  });

  test('rawstring', () {
    expect(KdlTokenizer('#"foo\\nbar"#').nextToken(),
        equals(KdlToken(KdlTerm.rawstring, "foo\\nbar")));
    expect(KdlTokenizer('#"foo"bar"#').nextToken(),
        equals(KdlToken(KdlTerm.rawstring, "foo\"bar")));
    expect(KdlTokenizer('##"foo"#bar"##').nextToken(),
        equals(KdlToken(KdlTerm.rawstring, "foo\"#bar")));
    expect(KdlTokenizer('#""foo""#').nextToken(),
        equals(KdlToken(KdlTerm.rawstring, "\"foo\"")));

    var tokenizer = KdlTokenizer('node #"C:\\Users\\zkat\\"#');
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, "node")));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, " ", 1, 5)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.rawstring, "C:\\Users\\zkat\\", 1, 6)));

    tokenizer = KdlTokenizer('other-node #"hello"world"#');
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, "other-node")));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.whitespace, " ", 1, 11)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.rawstring, "hello\"world", 1, 12)));
  });

  test('integer', () {
    expect(KdlTokenizer("123").nextToken(),
        equals(KdlToken(KdlTerm.integer, 123)));
    expect(KdlTokenizer("0x0123456789abcdef").nextToken(),
        equals(KdlToken(KdlTerm.integer, 0x0123456789abcdef)));
    expect(KdlTokenizer("0o01234567").nextToken(),
        equals(KdlToken(KdlTerm.integer, 342391)));
    expect(KdlTokenizer("0b101001").nextToken(),
        equals(KdlToken(KdlTerm.integer, 41)));
    expect(KdlTokenizer("-0x0123456789abcdef").nextToken(),
        equals(KdlToken(KdlTerm.integer, -0x0123456789abcdef)));
    expect(KdlTokenizer("-0o01234567").nextToken(),
        equals(KdlToken(KdlTerm.integer, -342391)));
    expect(KdlTokenizer("-0b101001").nextToken(),
        equals(KdlToken(KdlTerm.integer, -41)));
    expect(KdlTokenizer("+0x0123456789abcdef").nextToken(),
        equals(KdlToken(KdlTerm.integer, 0x0123456789abcdef)));
    expect(KdlTokenizer("+0o01234567").nextToken(),
        equals(KdlToken(KdlTerm.integer, 342391)));
    expect(KdlTokenizer("+0b101001").nextToken(),
        equals(KdlToken(KdlTerm.integer, 41)));
  });

  test('float', () {
    expect(KdlTokenizer("1.23").nextToken(),
        equals(KdlToken(KdlTerm.decimal, BigDecimal.parse('1.23'))));
    expect(KdlTokenizer("#inf").nextToken(),
        equals(KdlToken(KdlTerm.double, double.infinity)));
    expect(KdlTokenizer("#-inf").nextToken(),
        equals(KdlToken(KdlTerm.double, -double.infinity)));
    var nan = KdlTokenizer("#nan").nextToken();
    expect(nan.type, equals(KdlTerm.double));
    expect(nan.value, isNaN);
  });

  test('boolean', () {
    expect(KdlTokenizer("#true").nextToken(),
        equals(KdlToken(KdlTerm.trueKeyword, true)));
    expect(KdlTokenizer("#false").nextToken(),
        equals(KdlToken(KdlTerm.falseKeyword, false)));
  });

  test('null', () {
    expect(KdlTokenizer("#null").nextToken(),
        equals(KdlToken(KdlTerm.nullKeyword, null)));
  });

  test('symbols', () {
    expect(
        KdlTokenizer("{").nextToken(), equals(KdlToken(KdlTerm.lbrace, '{')));
    expect(
        KdlTokenizer("}").nextToken(), equals(KdlToken(KdlTerm.rbrace, '}')));
  });

  test('equals', () {
    expect(
        KdlTokenizer("=").nextToken(), equals(KdlToken(KdlTerm.equals, '=')));
    expect(
        KdlTokenizer(" =").nextToken(), equals(KdlToken(KdlTerm.equals, ' =')));
    expect(
        KdlTokenizer("= ").nextToken(), equals(KdlToken(KdlTerm.equals, '= ')));
    expect(KdlTokenizer(" = ").nextToken(),
        equals(KdlToken(KdlTerm.equals, ' = ')));
    expect(KdlTokenizer(" =foo").nextToken(),
        equals(KdlToken(KdlTerm.equals, ' =')));
  });

  test('whitespace', () {
    expect(KdlTokenizer(" ").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, ' ')));
    expect(KdlTokenizer("\t").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, "\t")));
    expect(KdlTokenizer("    \t").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, "    \t")));
    expect(KdlTokenizer("\\\n").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, "\\\n")));
    expect(KdlTokenizer("\\").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, "\\")));
    expect(KdlTokenizer("\\//some comment\n").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, "\\\n")));
    expect(KdlTokenizer("\\ //some comment\n").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, "\\ \n")));
    expect(KdlTokenizer("\\//some comment").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, "\\")));
    expect(KdlTokenizer(" \\\n").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, " \\\n")));
    expect(KdlTokenizer(" \\//some comment\n").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, " \\\n")));
    expect(KdlTokenizer(" \\ //some comment\n").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, " \\ \n")));
    expect(KdlTokenizer(" \\//some comment").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, " \\")));
    expect(KdlTokenizer(" \\\n  \\\n  ").nextToken(),
        equals(KdlToken(KdlTerm.whitespace, " \\\n  \\\n  ")));
  });

  test('multiple_tokens', () {
    var tokenizer = KdlTokenizer("node 1 \"two\" a=3");

    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node', 1, 1)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ', 1, 5)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.integer, 1, 1, 6)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ', 1, 7)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.string, 'two', 1, 8)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.whitespace, ' ', 1, 13)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'a', 1, 14)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.equals, '=', 1, 15)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.integer, 3, 1, 16)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '', 1, 17)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null, 1, 17)));
  });

  test('single_line_comment', () {
    expect(KdlTokenizer("// comment").nextToken(),
        equals(KdlToken(KdlTerm.eof, '')));

    var tokenizer = KdlTokenizer("""
node1
// comment
node2
    """
        .trim());

    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node1', 1, 1)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n", 1, 6)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n", 2, 11)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node2', 3, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '', 3, 6)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null, 3, 6)));
  });

  test('multiline_comment', () {
    var tokenizer = KdlTokenizer("foo /*bar=1*/ baz=2");

    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'foo', 1, 1)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.whitespace, '  ', 1, 4)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'baz', 1, 15)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.equals, '=', 1, 18)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.integer, 2, 1, 19)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '', 1, 20)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null, 1, 20)));
  });

  test('utf8', () {
    expect(
        KdlTokenizer("😁").nextToken(), equals(KdlToken(KdlTerm.ident, '😁')));
    expect(KdlTokenizer('"😁"').nextToken(),
        equals(KdlToken(KdlTerm.string, '😁')));
    expect(KdlTokenizer('ノード').nextToken(),
        equals(KdlToken(KdlTerm.ident, 'ノード')));
    expect(KdlTokenizer('お名前').nextToken(),
        equals(KdlToken(KdlTerm.ident, 'お名前')));
    expect(KdlTokenizer('"☜(ﾟヮﾟ☜)"').nextToken(),
        equals(KdlToken(KdlTerm.string, '☜(ﾟヮﾟ☜)')));

    var tokenizer = KdlTokenizer("""
smile "😁"
ノード お名前="☜(ﾟヮﾟ☜)"
    """
        .trim());

    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'smile', 1, 1)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ', 1, 6)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.string, '😁', 1, 7)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n", 1, 10)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'ノード', 2, 1)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ', 2, 4)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'お名前', 2, 5)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.equals, '=', 2, 8)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.string, '☜(ﾟヮﾟ☜)', 2, 9)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '', 2, 18)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null, 2, 18)));
  });

  test('semicolon', () {
    var tokenizer = KdlTokenizer('node1; node2');

    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node1', 1, 1)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.semicolon, ';', 1, 6)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ', 1, 7)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'node2', 1, 8)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '', 1, 13)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null, 1, 13)));
  });

  test('slash_dash', () {
    var tokenizer = KdlTokenizer("""
/-mynode /-"foo" /-key=1 /-{
  a
}
    """
        .trim());

    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.slashdash, '/-', 1, 1)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'mynode', 1, 3)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.whitespace, ' ', 1, 9)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.slashdash, '/-', 1, 10)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.string, 'foo', 1, 12)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.whitespace, ' ', 1, 17)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.slashdash, '/-', 1, 18)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'key', 1, 20)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.equals, '=', 1, 23)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.integer, 1, 1, 24)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.whitespace, ' ', 1, 25)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.slashdash, '/-', 1, 26)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.lbrace, '{', 1, 28)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n", 1, 29)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.whitespace, '  ', 2, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'a', 2, 3)));
    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.newline, "\n", 2, 4)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rbrace, '}', 3, 1)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '', 3, 2)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null, 3, 2)));
  });

  test('multiline_nodes', () {
    var tokenizer = KdlTokenizer("""
title \\
  "Some title"
    """
        .trim());

    expect(
        tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'title', 1, 1)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.whitespace, " \\\n  ", 1, 6)));
    expect(tokenizer.nextToken(),
        equals(KdlToken(KdlTerm.string, 'Some title', 2, 3)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, '', 2, 15)));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.eof, null, 2, 15)));
  });

  test('types', () {
    var tokenizer = KdlTokenizer("(foo)bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.lparen, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rparen, ')')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'bar')));

    tokenizer = KdlTokenizer("(foo)/*asdf*/bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.lparen, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rparen, ')')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'bar')));

    tokenizer = KdlTokenizer("(foo/*asdf*/)bar");
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.lparen, '(')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'foo')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.rparen, ')')));
    expect(tokenizer.nextToken(), equals(KdlToken(KdlTerm.ident, 'bar')));
  });
}
