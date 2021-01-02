import 'package:kdl/src/tokenizer.dart';
import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/parser.dart';

void main() {
  KdlParser parser;

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
      equals(KdlDocument([
        KdlNode('node1'),
        KdlNode('node2')
      ]))
    );
  });

  test('node', () {
    expect(parser.parse('node;'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse('node 1'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(1)])])));
    expect(parser.parse('node 1 2 "3" true false null'), equals(KdlDocument([
      KdlNode('node', arguments: [
        KdlInt(1),
        KdlInt(2),
        KdlString("3"),
        KdlBool(true),
        KdlBool(false),
        KdlNull()
      ])
    ])));
    expect(parser.parse("node {\n  node2\n}"), equals(KdlDocument([KdlNode('node', children: [KdlNode('node2')])])));
    expect(parser.parse("node { node2; }"), equals(KdlDocument([KdlNode('node', children: [KdlNode('node2')])])));
  });

  test('node_slashdash_comment', () {
    expect(parser.parse('/-node'), equals(KdlDocument([])));
    expect(parser.parse('/- node'), equals(KdlDocument([])));
    expect(parser.parse("/- node\n"), equals(KdlDocument([])));
    expect(parser.parse('/-node 1 2 3'), equals(KdlDocument([])));
    expect(parser.parse('/-node key=false'), equals(KdlDocument([])));
    expect(parser.parse("/-node{\nnode\n}"), equals(KdlDocument([])));
    expect(parser.parse("/-node 1 2 3 key=\"value\" \\\n{\nnode\n}"), equals(KdlDocument([])));
  });

  test('arg_slashdash_comment', () {
    expect(parser.parse('node /-1'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse('node /-1 2'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(2)])])));
    expect(parser.parse('node 1 /- 2 3'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(1), KdlInt(3)])])));
    expect(parser.parse('node /--1'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse('node /- -1'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("node \\\n/- -1"), equals(KdlDocument([KdlNode('node')])));
  });

  test('prop_slashdash_comment', () {
    expect(parser.parse('node /-key=1'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse('node /- key=1'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse('node key=1 /-key2=2'), equals(KdlDocument([KdlNode('node', properties: { 'key': KdlInt(1) })])));
  });

  test('children_slashdash_comment', () {
    expect(parser.parse('node /-{}'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse('node /- {}'), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("node /-{\nnode2\n}"), equals(KdlDocument([KdlNode('node')])));
  });

  test('string', () {
    expect(parser.parse('node ""'), equals(KdlDocument([KdlNode('node', arguments: [KdlString("")])])));
    expect(parser.parse('node "hello"'), equals(KdlDocument([KdlNode('node', arguments: [KdlString("hello")])])));
    expect(parser.parse(r'node "hello\nworld"'), equals(KdlDocument([KdlNode('node', arguments: [KdlString("hello\nworld")])])));
    expect(parser.parse(r'node "\u{10FFF}"'), equals(KdlDocument([KdlNode('node', arguments: [KdlString("\u{10FFF}")])])));
    expect(parser.parse(r'node "\"\\\/\b\f\n\r\t"'), equals(KdlDocument([KdlNode('node', arguments: [KdlString("\"\\/\u{08}\u{0C}\n\r\t")])])));
    expect(parser.parse(r'node "\u{10}"'), equals(KdlDocument([KdlNode('node', arguments: [KdlString("\u{10}")])])));
    expect(() { parser.parse(r'node "\i"'); }, throwsA(anything));
    expect(() { parser.parse(r'node "\u{c0ffee}"'); }, throwsA(anything));
  });

  test('float', () {
    expect(parser.parse('node 1.0'), equals(KdlDocument([KdlNode('node', arguments: [KdlFloat(1.0)])])));
    expect(parser.parse('node 0.0'), equals(KdlDocument([KdlNode('node', arguments: [KdlFloat(0.0)])])));
    expect(parser.parse('node -1.0'), equals(KdlDocument([KdlNode('node', arguments: [KdlFloat(-1.0)])])));
    expect(parser.parse('node +1.0'), equals(KdlDocument([KdlNode('node', arguments: [KdlFloat(1.0)])])));
    expect(parser.parse('node 1.0e10'), equals(KdlDocument([KdlNode('node', arguments: [KdlFloat(1.0e10)])])));
    expect(parser.parse('node 1.0e-10'), equals(KdlDocument([KdlNode('node', arguments: [KdlFloat(1.0e-10)])])));
    expect(parser.parse('node 123_456_789.0'), equals(KdlDocument([KdlNode('node', arguments: [KdlFloat(123456789.0)])])));
    expect(parser.parse('node 123_456_789.0_'), equals(KdlDocument([KdlNode('node', arguments: [KdlFloat(123456789.0)])])));
    expect(() { parser.parse('node ?1.0'); }, throwsA(anything));
    expect(() { parser.parse('node _1.0'); }, throwsA(anything));
    expect(() { parser.parse('node 1._0'); }, throwsA(anything));
    expect(() { parser.parse('node 1.'); }, throwsA(anything));
    expect(() { parser.parse('node .0'); }, throwsA(anything));
  });

  test('integer', () {
    expect(parser.parse('node 0'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(0)])])));
    expect(parser.parse('node 0123456789'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(123456789)])])));
    expect(parser.parse('node 0123_456_789'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(123456789)])])));
    expect(parser.parse('node 0123_456_789_'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(123456789)])])));
    expect(parser.parse('node +0123456789'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(123456789)])])));
    expect(parser.parse('node -0123456789'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(-123456789)])])));
    expect(() { parser.parse('node ?0123456789'); }, throwsA(anything));
    expect(() { parser.parse('node _0123456789'); }, throwsA(anything));
    expect(() { parser.parse('node a'); }, throwsA(anything));
    expect(() { parser.parse('node --'); }, throwsA(anything));
  });

  test('hexadecimal', () {
    expect(parser.parse('node 0x0123456789abcdef'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(0x0123456789abcdef)])])));
    expect(parser.parse('node 0x01234567_89abcdef'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(0x0123456789abcdef)])])));
    expect(parser.parse('node 0x01234567_89abcdef_'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(0x0123456789abcdef)])])));
    expect(() { parser.parse('node 0x_123'); }, throwsA(anything));
    expect(() { parser.parse('node 0xg'); }, throwsA(anything));
    expect(() { parser.parse('node 0xx'); }, throwsA(anything));
  });

  test('octal', () {
    expect(parser.parse('node 0o01234567'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(342391)])])));
    expect(parser.parse('node 0o0123_4567'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(342391)])])));
    expect(parser.parse('node 0o01234567_'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(342391)])])));
    expect(() { parser.parse('node 0o_123'); }, throwsA(anything));
    expect(() { parser.parse('node 0o8'); }, throwsA(anything));
    expect(() { parser.parse('node 0oo'); }, throwsA(anything));
  });

  test('binary', () {
    expect(parser.parse('node 0b0101'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(5)])])));
    expect(parser.parse('node 0b01_10'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(6)])])));
    expect(parser.parse('node 0b01___10'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(6)])])));
    expect(parser.parse('node 0b0110_'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(6)])])));
    expect(() { parser.parse('node 0b_0110'); }, throwsA(anything));
    expect(() { parser.parse('node 0b20'); }, throwsA(anything));
    expect(() { parser.parse('node 0bb'); }, throwsA(anything));
  });

  test('raw_string', () {
    expect(parser.parse(r'node r"foo"'), equals(KdlDocument([KdlNode('node', arguments: [KdlString('foo')])])));
    expect(parser.parse(r'node r"foo\nbar"'), equals(KdlDocument([KdlNode('node', arguments: [KdlString(r'foo\nbar')])])));
    expect(parser.parse(r'node r#"foo"#'), equals(KdlDocument([KdlNode('node', arguments: [KdlString('foo')])])));
    expect(parser.parse(r'node r##"foo"##'), equals(KdlDocument([KdlNode('node', arguments: [KdlString('foo')])])));
    expect(parser.parse(r'node r"\nfoo\r"'), equals(KdlDocument([KdlNode('node', arguments: [KdlString(r'\nfoo\r')])])));
    expect(() { parser.parse('node r##"foo"#'); }, throwsA(anything));
  });

  test('boolean', () {
    expect(parser.parse('node true'), equals(KdlDocument([KdlNode('node', arguments: [KdlBool(true)])])));
    expect(parser.parse('node false'), equals(KdlDocument([KdlNode('node', arguments: [KdlBool(false)])])));
  });

  test('node_space', () {
    expect(parser.parse('node 1'), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(1)])])));
    expect(parser.parse("node\t1"), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(1)])])));
    expect(parser.parse("node\t \\ // hello\n 1"), equals(KdlDocument([KdlNode('node', arguments: [KdlInt(1)])])));
  });

  test('single_line_comment', () {
    expect(parser.parse('//hello'), equals(KdlDocument([])));
    expect(parser.parse("// \thello"), equals(KdlDocument([])));
    expect(parser.parse("//hello\n"), equals(KdlDocument([])));
    expect(parser.parse("//hello\r\n"), equals(KdlDocument([])));
    expect(parser.parse("//hello\n\r"), equals(KdlDocument([])));
    expect(parser.parse("//hello\rworld"), equals(KdlDocument([KdlNode('world')])));
    expect(parser.parse("//hello\nworld\r\n"), equals(KdlDocument([KdlNode('world')])));
  });

  test('multi_line_comment', () {
    expect(parser.parse("/*hello*/"), equals(KdlDocument([])));
    expect(parser.parse("/*hello*/\n"), equals(KdlDocument([])));
    expect(parser.parse("/*\nhello\r\n*/"), equals(KdlDocument([])));
    expect(parser.parse("/*\nhello** /\n*/"), equals(KdlDocument([])));
    expect(parser.parse("/**\nhello** /\n*/"), equals(KdlDocument([])));
    expect(parser.parse('/*hello*/world'), equals(KdlDocument([KdlNode('world')])));
  });

  test('escline', () {
    expect(parser.parse("\\\nfoo"), equals(KdlDocument([KdlNode('foo')])));
    expect(parser.parse("\\\n  foo"), equals(KdlDocument([KdlNode('foo')])));
    expect(parser.parse("\\  \t \nfoo"), equals(KdlDocument([KdlNode('foo')])));
    expect(parser.parse("\\ // test \nfoo"), equals(KdlDocument([KdlNode('foo')])));
    expect(parser.parse("\\ // test \n  foo"), equals(KdlDocument([KdlNode('foo')])));
  });

  test('whitespace', () {
    expect(parser.parse(" node"), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("\tnode"), equals(KdlDocument([KdlNode('node')])));
    expect(parser.parse("/* \nfoo\r\n */ etc"), equals(KdlDocument([KdlNode('etc')])));
  });

  test('newline', () {
    expect(parser.parse("node1\nnode2"), equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
    expect(parser.parse("node1\rnode2"), equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
    expect(parser.parse("node1\r\nnode2"), equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
    expect(parser.parse("node1\n\nnode2"), equals(KdlDocument([KdlNode('node1'), KdlNode('node2')])));
  });

  // test('basic', () {
  //   doc = parser.parse('title "Hello, World"')
  //   nodes = nodes! {
  //     title "Hello, World"
  //   }
  //   expect(nodes, doc
  // });

  // test('multiple_values', () {
  //   doc = parser.parse('bookmarks 12 15 188 1234')
  //   nodes = nodes! {
  //     bookmarks 12, 15, 188, 1234
  //   }
  //   expect(nodes, doc
  // });

  // test('properties', () {
  //   doc = parser.parse <<~KDL
  //     author "Alex Monad" email="alex@example.com" active=true
  //     foo bar=true "baz" quux=false 1 2 3
  //   KDL
  //   nodes = nodes! {
  //     author "Alex Monad", email: "alex@example.com", active: true
  //     foo "baz", 1, 2, 3, bar: true, quux: false
  //   }
  //   expect(nodes, doc
  // });

  // test('nested_child_nodes', () {
  //   doc = parser.parse <<~KDL
  //     contents {
  //       section "First section" {
  //         paragraph "This is the first paragraph"
  //         paragraph "This is the second paragraph"
  //       }
  //     }
  //   KDL
  //   nodes = nodes! {
  //     contents {
  //       section("First section") {
  //         paragraph "This is the first paragraph"
  //         paragraph "This is the second paragraph"
  //       }
  //     }
  //   }
  //   expect(nodes, doc
  // });

  // test('semicolon', () {
  //   doc = parser.parse('node1; node2; node3;')
  //   nodes = nodes! {
  //     node1; node2; node3;
  //   }
  //   expect(nodes, doc
  // });

  // test('raw_strings', () {
  //   doc = parser.parse <<~KDL
  //     node "this\\nhas\\tescapes"
  //     other r"C:\\Users\\zkat\\"
  //     other-raw r#"hello"world"#
  //   KDL
  //   nodes = nodes! {
  //     node "this\nhas\tescapes"
  //     other "C:\\Users\\zkat\\"
  //     _ 'other-raw', "hello\"world"
  //   }
  //   expect(nodes, doc
  // });

  // test('multiline_strings', () {
  //   doc = parser.parse <<~KDL
  //     string "my
  //     multiline
  //     value"
  //   KDL
  //   nodes = nodes! {
  //     string "my\nmultiline\nvalue"
  //   }
  //   expect(nodes, doc
  // });

  // test('numbers', () {
  //   doc = parser.parse <<~KDL
  //     num 1.234e-42
  //     my-hex 0xdeadbeef
  //     my-octal 0o755
  //     my-binary 0b10101101
  //     bignum 1_000_000
  //   KDL
  //   nodes = nodes! {
  //     num 1.234e-42
  //     _ 'my-hex', 0xdeadbeef
  //     _ 'my-octal', 0o755
  //     _ 'my-binary', 0b10101101
  //     bignum 1_000_000
  //   }
  //   expect(nodes, doc
  // });

  // test('comments', () {
  //   doc = parser.parse <<~KDL
  //     // C style

  //     /*
  //     C style multiline
  //     */

  //     tag /*foo=true*/ bar=false

  //     /*/*
  //     hello
  //     */*/
  //   KDL
  //   nodes = nodes! {
  //     tag bar: false
  //   }
  //   expect(nodes, doc
  // });

  // test('slash_dash', () {
  //   doc = parser.parse <<~KDL
  //     /-mynode "foo" key=1 {
  //       a
  //       b
  //       c
  //     }

  //     mynode /-"commented" "not commented" /-key="value" /-{
  //       a
  //       b
  //     }
  //   KDL

  //   nodes = nodes! {
  //     mynode "not commented"
  //   }
  //   expect(nodes, doc
  // });

  // test('multiline_nodes', () {
  //   doc = parser.parse <<~KDL
  //     title \\
  //       "Some title"

  //     my-node 1 2 \\  // comments are ok after \\
  //             3 4
  //   KDL
  //   nodes = nodes! {
  //     title "Some title"
  //     _ "my-node", 1, 2, 3, 4
  //   }
  //   expect(nodes, doc
  // });

  // test('utf8', () {
  //   doc = parser.parse <<~KDL
  //     smile "😁"
  //     ノード お名前＝"☜(ﾟヮﾟ☜)"
  //   KDL
  //   nodes = KdlDocument([
  //     KdlNode('smile', [KdlString('😁')]),
  //     KdlNode('ノード', [], { 'お名前' => KdlString('☜(ﾟヮﾟ☜)') })
  //   ])
  //   expect(nodes, doc
  // });

  // test('node_names', () {
  //   doc = parser.parse <<~KDL
  //     "!@#$@$%Q#$%~@!40" "1.2.3" "!!!!!"=true
  //     foo123~!@#$%^&*.:'|/?+ "weeee"
  //   KDL
  //   nodes = nodes! {
  //     _ "!@#$@$%Q#$%~@!40", "1.2.3", "!!!!!": true
  //     _ "foo123~!@#$%^&*.:'|/?+", "weeee"
  //   }
  //   expect(nodes, doc
  // });

  // test('escaping', () {
  //   doc = parser.parse <<~KDL
  //     node1 "\\u{1f600}"
  //     node2 "\\n\\t\\r\\\\\\"\\f\\b"
  //   KDL
  //   nodes = nodes! {
  //     node1 "😀"
  //     node2 "\n\t\r\\\"\f\b"
  //   }
  //   expect(nodes, doc
  // });
}