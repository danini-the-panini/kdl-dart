import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/parser.dart';

void main() {
  late KdlParser parser;

  setUp(() {
    parser = KdlParser();
  });

  test('parse_empty_string', () {
    expect(parser.parse(''), equals(KdlDocument([])));
    expect(parser.parse(' '), equals(KdlDocument([])));
    expect(parser.parse("\n"), equals(KdlDocument([])));
  });

  test('nodes', () {
    expect(parser.parse('node'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("node\n"), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("\nnode\n"), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("node1\nnode2"),
        equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
  });

  test('node', () {
    expect(parser.parse('node;'), equals(KdlDocument([KdlNode('node')])));
    expect(
        parser.parse('node 1'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(1)])
        ])));
    expect(
        parser.parse('node 1 2 "3" #true #false #null'),
        equals(KdlDocument([
          KdlNode('node', arguments: [
            KdlInt(1),
            KdlInt(2),
            KdlString("3"),
            KdlBool(true),
            KdlBool(false),
            KdlNull()
          ])
        ])));
    expect(
        parser.parse("node {\n  node2\n}"),
        equals(KdlDocument([
          KdlNode('node', children: [KdlNode('node2')])
        ])));
    expect(
        parser.parse("node {\n    node2    \n}"),
        equals(KdlDocument([
          KdlNode('node', children: [KdlNode('node2')])
        ])));
    expect(
        parser.parse("node { node2; }"),
        equals(KdlDocument([
          KdlNode('node', children: [KdlNode('node2')])
        ])));
    expect(
        parser.parse("node { node2 }"),
        equals(KdlDocument([
          KdlNode('node', children: [KdlNode('node2')])
        ])));
    expect(
        parser.parse("node { node2; node3 }"),
        equals(KdlDocument([
          KdlNode('node', children: [KdlNode('node2'), KdlNode('node3')])
        ])));
  });

  test('node_slashdash_comment', () {
    expect(parser.parse('/-node'), equals(KdlDocument([])));
    expect(parser.parse('/- node'), equals(KdlDocument([])));
    expect(parser.parse("/- node\n"), equals(KdlDocument([])));
    expect(parser.parse('/-node 1 2 3'), equals(KdlDocument([])));
    expect(parser.parse('/-node key=#false'), equals(KdlDocument([])));
    expect(parser.parse("/-node{\nnode\n}"), equals(KdlDocument([])));
    expect(parser.parse("/-node 1 2 3 key=\"value\" \\\n{\nnode\n}"),
        equals(KdlDocument([])));
  });

  test('arg_slashdash_comment', () {
    expect(parser.parse('node /-1'), equals(KdlDocument([KdlNode('node')])));
    expect(
        parser.parse('node /-1 2'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(2)])
        ])));
    expect(
        parser.parse('node 1 /- 2 3'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(1), KdlInt(3)])
        ])));
    expect(parser.parse('node /--1'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse('node /- -1'), equals(KdlDocument([KdlNode('node')])));
    expect(
        parser.parse("node \\\n/- -1"), equals(KdlDocument([KdlNode('node')])));
  });

  test('prop_slashdash_comment', () {
    expect(
        parser.parse('node /-key=1'), equals(KdlDocument([KdlNode('node')])));
    expect(
        parser.parse('node /- key=1'), equals(KdlDocument([KdlNode('node')])));
    expect(
        parser.parse('node key=1 /-key2=2'),
        equals(KdlDocument([
          KdlNode('node', properties: {'key': KdlInt(1)})
        ])));
  });

  test('children_slashdash_comment', () {
    expect(parser.parse('node /-{}'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse('node /- {}'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("node /-{\nnode2\n}"),
        equals(KdlDocument([KdlNode('node')])));
  });

  test('string', () {
    expect(
        parser.parse('node ""'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("")])
        ])));
    expect(
        parser.parse('node "hello"'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("hello")])
        ])));
    expect(
        parser.parse(r'node "hello\nworld"'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("hello\nworld")])
        ])));
    expect(
        parser.parse(r'node -flag'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("-flag")])
        ])));
    expect(
        parser.parse(r'node --flagg'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("--flagg")])
        ])));
    expect(
        parser.parse(r'node "\u{10FFF}"'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("\u{10FFF}")])
        ])));
    expect(
        parser.parse(r'node "\"\\\b\f\n\r\t"'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("\"\\\u{08}\u{0C}\n\r\t")])
        ])));
    expect(
        parser.parse(r'node "\u{10}"'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("\u{10}")])
        ])));
    expect(() {
      parser.parse(r'node "\i"');
    }, throwsA(anything));
    expect(() {
      parser.parse(r'node "\u{c0ffee}"');
    }, throwsA(anything));
    expect(() {
      parser.parse(r'node "oops');
    }, throwsA(anything));
  });

  test('unindented multiline strings', () {
    expect(
        parser.parse('node """\n  foo\n  bar\n    baz\n  qux\n  """'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("foo\nbar\n  baz\nqux")])
        ])));
    expect(
        parser.parse('node #"""\n  foo\n  bar\n    baz\n  qux\n  """#'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString("foo\nbar\n  baz\nqux")])
        ])));
    expect(() {
      parser.parse('node """\n    foo\n  bar\n    baz\n    """');
    }, throwsA(anything));
    expect(() {
      parser.parse('node #"""\n    foo\n  bar\n    baz\n    """#');
    }, throwsA(anything));
  });

  test('float', () {
    expect(
        parser.parse('node 1.0'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBigDecimal.from(1.0)])
        ])));
    expect(
        parser.parse('node 0.0'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBigDecimal.from(0.0)])
        ])));
    expect(
        parser.parse('node -1.0'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBigDecimal.from(-1.0)])
        ])));
    expect(
        parser.parse('node +1.0'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBigDecimal.from(1.0)])
        ])));
    expect(
        parser.parse('node 1.0e10'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBigDecimal.from(1.0e10)])
        ])));
    expect(
        parser.parse('node 1.0e-10'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBigDecimal.from(1.0e-10)])
        ])));
    expect(
        parser.parse('node 123_456_789.0'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBigDecimal.from(123456789.0)])
        ])));
    expect(
        parser.parse('node 123_456_789.0_'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBigDecimal.from(123456789.0)])
        ])));
    expect(() {
      parser.parse('node 1._0');
    }, throwsA(anything));
    expect(() {
      parser.parse('node 1.');
    }, throwsA(anything));
    expect(() {
      parser.parse('node 1.0v2');
    }, throwsA(anything));
    expect(() {
      parser.parse('node -1em');
    }, throwsA(anything));
    expect(() {
      parser.parse('node .0');
    }, throwsA(anything));
  });

  test('integer', () {
    expect(
        parser.parse('node 0'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(0)])
        ])));
    expect(
        parser.parse('node 0123456789'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(123456789)])
        ])));
    expect(
        parser.parse('node 0123_456_789'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(123456789)])
        ])));
    expect(
        parser.parse('node 0123_456_789_'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(123456789)])
        ])));
    expect(
        parser.parse('node +0123456789'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(123456789)])
        ])));
    expect(
        parser.parse('node -0123456789'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(-123456789)])
        ])));
  });

  test('hexadecimal', () {
    expect(
        parser.parse('node 0x0123456789abcdef'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(0x0123456789abcdef)])
        ])));
    expect(
        parser.parse('node 0x01234567_89abcdef'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(0x0123456789abcdef)])
        ])));
    expect(
        parser.parse('node 0x01234567_89abcdef_'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(0x0123456789abcdef)])
        ])));
    expect(() {
      parser.parse('node 0x_123');
    }, throwsA(anything));
    expect(() {
      parser.parse('node 0xg');
    }, throwsA(anything));
    expect(() {
      parser.parse('node 0xx');
    }, throwsA(anything));
  });

  test('octal', () {
    expect(
        parser.parse('node 0o01234567'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(342391)])
        ])));
    expect(
        parser.parse('node 0o0123_4567'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(342391)])
        ])));
    expect(
        parser.parse('node 0o01234567_'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(342391)])
        ])));
    expect(() {
      parser.parse('node 0o_123');
    }, throwsA(anything));
    expect(() {
      parser.parse('node 0o8');
    }, throwsA(anything));
    expect(() {
      parser.parse('node 0oo');
    }, throwsA(anything));
  });

  test('binary', () {
    expect(
        parser.parse('node 0b0101'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(5)])
        ])));
    expect(
        parser.parse('node 0b01_10'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(6)])
        ])));
    expect(
        parser.parse('node 0b01___10'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(6)])
        ])));
    expect(
        parser.parse('node 0b0110_'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(6)])
        ])));
    expect(() {
      parser.parse('node 0b_0110');
    }, throwsA(anything));
    expect(() {
      parser.parse('node 0b20');
    }, throwsA(anything));
    expect(() {
      parser.parse('node 0bb');
    }, throwsA(anything));
  });

  test('raw_string', () {
    expect(
        parser.parse(r'node #"foo"#'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString('foo')])
        ])));
    expect(
        parser.parse(r'node #"foo\nbar"#'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString(r'foo\nbar')])
        ])));
    expect(
        parser.parse(r'node #"foo"#'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString('foo')])
        ])));
    expect(
        parser.parse(r'node ##"foo"##'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString('foo')])
        ])));
    expect(
        parser.parse(r'node #"\nfoo\r"#'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlString(r'\nfoo\r')])
        ])));
    expect(() {
      parser.parse('node ##"foo"#');
    }, throwsA(anything));
  });

  test('boolean', () {
    expect(
        parser.parse('node #true'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBool(true)])
        ])));
    expect(
        parser.parse('node #false'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlBool(false)])
        ])));
  });

  test('null', () {
    expect(
        parser.parse('node #null'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlNull()])
        ])));
  });

  test('node_space', () {
    expect(
        parser.parse('node 1'),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(1)])
        ])));
    expect(
        parser.parse("node\t1"),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(1)])
        ])));
    expect(
        parser.parse("node\t \\ // hello\n 1"),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(1)])
        ])));
  });

  test('single_line_comment', () {
    expect(parser.parse('//hello'), equals(KdlDocument([])));
    expect(parser.parse("// \thello"), equals(KdlDocument([])));
    expect(parser.parse("//hello\n"), equals(KdlDocument([])));
    expect(parser.parse("//hello\r\n"), equals(KdlDocument([])));
    expect(parser.parse("//hello\n\r"), equals(KdlDocument([])));
    expect(parser.parse("//hello\rworld"),
        equals(KdlDocument([KdlNode('world')])));
    expect(parser.parse("//hello\nworld\r\n"),
        equals(KdlDocument([KdlNode('world')])));
  });

  test('multi_line_comment', () {
    expect(parser.parse("/*hello*/"), equals(KdlDocument([])));
    expect(parser.parse("/*hello*/\n"), equals(KdlDocument([])));
    expect(parser.parse("/*\nhello\r\n*/"), equals(KdlDocument([])));
    expect(parser.parse("/*\nhello** /\n*/"), equals(KdlDocument([])));
    expect(parser.parse("/**\nhello** /\n*/"), equals(KdlDocument([])));
    expect(parser.parse('/*hello*/world'),
        equals(KdlDocument([KdlNode('world')])));
  });

  test('escline', () {
    expect(
        parser.parse("node\\\n  1"),
        equals(KdlDocument([
          KdlNode('node', arguments: [KdlInt(1)])
        ])));
    expect(parser.parse("node\\\n"), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("node\\ \n"), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("node\\\n "), equals(KdlDocument([KdlNode('node')])));
    expect(() {
      parser.parse('node \\foo');
    }, throwsA(anything));
    expect(() {
      parser.parse('node\\\\\nnode2');
    }, throwsA(anything));
    expect(() {
      parser.parse('node \\\\\nnode2');
    }, throwsA(anything));
  });

  test('whitespace', () {
    expect(parser.parse(" node"), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("\tnode"), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("/* \nfoo\r\n */ etc"),
        equals(KdlDocument([KdlNode('etc')])));
  });

  test('newline', () {
    expect(parser.parse("node1\nnode2"),
        equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
    expect(parser.parse("node1\rnode2"),
        equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
    expect(parser.parse("node1\r\nnode2"),
        equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
    expect(parser.parse("node1\n\nnode2"),
        equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
  });

  test('basic', () {
    var doc = parser.parse('title "Hello, World"');
    var nodes = KdlDocument([
      KdlNode('title', arguments: [KdlString("Hello, World")]),
    ]);
    expect(doc, equals(nodes));
  });

  test('multiple values', () {
    var doc = parser.parse('bookmarks 12 15 188 1234');
    var nodes = KdlDocument([
      KdlNode('bookmarks',
          arguments: [KdlInt(12), KdlInt(15), KdlInt(188), KdlInt(1234)]),
    ]);
    expect(doc, equals(nodes));
  });

  test('properties', () {
    var doc = parser.parse("""
author "Alex Monad" email="alex@example.com" active= #true
foo bar =#true "baz" quux =\\
  #false 1 2 3
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode(
        'author',
        arguments: [KdlString("Alex Monad")],
        properties: {
          'email': KdlString("alex@example.com"),
          'active': KdlBool(true),
        },
      ),
      KdlNode(
        'foo',
        arguments: [KdlString("baz"), KdlInt(1), KdlInt(2), KdlInt(3)],
        properties: {
          'bar': KdlBool(true),
          'quux': KdlBool(false),
        },
      ),
    ]);
    expect(doc, equals(nodes));
  });

  test('nested child nodes', () {
    var doc = parser.parse("""
contents {
  section "First section" {
    paragraph "This is the first paragraph"
    paragraph "This is the second paragraph"
  }
}
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('contents', children: [
        KdlNode('section', arguments: [
          KdlString("First section")
        ], children: [
          KdlNode('paragraph',
              arguments: [KdlString("This is the first paragraph")]),
          KdlNode('paragraph',
              arguments: [KdlString("This is the second paragraph")]),
        ]),
      ]),
    ]);
    expect(doc, equals(nodes));
  });

  test('semicolon', () {
    var doc = parser.parse("node1; node2; node3;");
    var nodes = KdlDocument([
      KdlNode('node1'),
      KdlNode('node2'),
      KdlNode('node3'),
    ]);
    expect(doc, equals(nodes));
  });

  test('optional child semicolon', () {
    var doc = parser.parse('node {foo;bar;baz}');
    var nodes = KdlDocument([
      KdlNode('node', children: [
        KdlNode('foo'),
        KdlNode('bar'),
        KdlNode('baz'),
      ]),
    ]);
    expect(doc, equals(nodes));
  });

  test('raw strings', () {
    var doc = parser.parse("""
node "this\\nhas\\tescapes"
other #"C:\\Users\\zkat\\"#
other-raw #"hello"world"#
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('node', arguments: [KdlString("this\nhas\tescapes")]),
      KdlNode('other', arguments: [KdlString("C:\\Users\\zkat\\")]),
      KdlNode('other-raw', arguments: [KdlString("hello\"world")]),
    ]);
    expect(doc, equals(nodes));
  });

  test('multiline strings', () {
    var doc = parser.parse("""
string \"""
my
multiline
value
\"""
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('string', arguments: [KdlString("my\nmultiline\nvalue")]),
    ]);
    expect(doc, equals(nodes));

    expect(() {
      parser.parse('node """foo"""');
    }, throwsA(anything));
    expect(() {
      parser.parse('node #"""foo"""#');
    }, throwsA(anything));
    expect(() {
      parser.parse('node """\n  oops');
    }, throwsA(anything));
    expect(() {
      parser.parse('node #"""\n  oops');
    }, throwsA(anything));
  });

  test('numbers', () {
    var doc = parser.parse("""
      num 1.234e-42
      my-hex 0xdeadbeef
      my-octal 0o755
      my-binary 0b10101101
      bignum 1_000_000
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('num', arguments: [KdlBigDecimal(BigDecimal.parse('1.234e-42'))]),
      KdlNode('my-hex', arguments: [KdlInt(0xdeadbeef)]),
      KdlNode('my-octal', arguments: [KdlInt(493)]),
      KdlNode('my-binary', arguments: [KdlInt(173)]),
      KdlNode('bignum', arguments: [KdlInt(1000000)]),
    ]);
    expect(doc, equals(nodes));
  });

  test('comments', () {
    var doc = parser.parse("""
      // C style

      /*
      C style multiline
      */

      tag /*foo=#true*/ bar=#false

      /*/*
      hello
      */*/
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('tag', properties: {'bar': KdlBool(false)})
    ]);
    expect(doc, equals(nodes));
  });

  test('slash dash', () {
    var doc = parser.parse("""
/-mynode "foo" key=1 {
  a
  b
  c
}

mynode /- "commented" "not commented" /-key="value" /-{
  a
  b
}
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('mynode', arguments: [KdlString("not commented")]),
    ]);
    expect(doc, equals(nodes));
  });

  test('multiline nodes', () {
    var doc = parser.parse("""
title \\
  "Some title"

my-node 1 2 \\  // comments are ok after \\
        3 4
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('title', arguments: [KdlString("Some title")]),
      KdlNode('my-node',
          arguments: [KdlInt(1), KdlInt(2), KdlInt(3), KdlInt(4)]),
    ]);
    expect(doc, equals(nodes));
  });

  test('utf8', () {
    var doc = parser.parse("""
smile "😁"
ノード お名前="☜(ﾟヮﾟ☜)"
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('smile', arguments: [KdlString('😁')]),
      KdlNode('ノード', properties: {'お名前': KdlString('☜(ﾟヮﾟ☜)')})
    ]);
    expect(doc, equals(nodes));
  });

  test('node_names', () {
    var doc = parser.parse(r"""
"!@$@$%Q$%~@!40" "1.2.3" "!!!!!"=#true
foo123~!@$%^&*.:'|?+ "weeee"
- 1
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode(r"!@$@$%Q$%~@!40",
          arguments: [KdlString("1.2.3")],
          properties: {"!!!!!": KdlBool(true)}),
      KdlNode(r"foo123~!@$%^&*.:'|?+", arguments: [KdlString("weeee")]),
      KdlNode('-', arguments: [KdlInt(1)]),
    ]);
    expect(doc, equals(nodes));
  });

  test('escaping', () {
    var doc = parser.parse("""
node1 "\\u{1f600}"
node2 "\\n\\t\\r\\\\\\"\\f\\b"
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('node1', arguments: [KdlString('😀')]),
      KdlNode('node2', arguments: [KdlString("\n\t\r\\\"\f\b")]),
    ]);
    expect(doc, equals(nodes));
  });

  test('node type', () {
    var doc = parser.parse("(foo)node");
    var nodes = KdlDocument([
      KdlNode('node', type: 'foo'),
    ]);
    expect(doc, equals(nodes));
  });

  test('value type', () {
    var doc = parser.parse('node (foo)"bar"');
    var nodes = KdlDocument([
      KdlNode('node', arguments: [KdlString("bar").asType("foo")]),
    ]);
    expect(doc, equals(nodes));
  });

  test('property type', () {
    var doc = parser.parse('node baz=(foo)"bar"');
    var nodes = KdlDocument([
      KdlNode('node', properties: {'baz': KdlString("bar").asType("foo")}),
    ]);
    expect(doc, equals(nodes));
  });

  test('child type', () {
    var doc = parser.parse("""
node {
  (foo)bar
}
    """
        .trim());
    var nodes = KdlDocument([
      KdlNode('node', children: [
        KdlNode('bar', type: 'foo'),
      ]),
    ]);
    expect(doc, equals(nodes));
  });

  test('version directive', () {
    var doc = parser.parse('/- kdl-version 2\nnode foo');
    expect(doc, isNotNull);

    expect(() {
      parser.parse('/- kdl-version 1\nnode "foo"');
    }, throwsA(anything));
  });
}
