import 'package:test/test.dart';

import '../lib/src/document.dart';

void main() {
  test('child', () {
    var node = KdlNode("node", children: [
      KdlNode("foo"),
      KdlNode("bar")
    ]);

    expect(node.child(0), node.children[0]);
    expect(node.child(1), node.children[1]);
    expect(node.child("foo"), node.children[0]);
    expect(node.child("bar"), node.children[1]);

    expect(() { node.child(null); }, throwsA(anything));
  });

  test('[]', () {
    var node = KdlNode("node", arguments: [
      KdlInt(1),
      KdlString("two"),
    ], properties: {
      'three': KdlInt(3),
      'four': KdlInt(4),
    });

    expect(node[0], 1);
    expect(node[1], "two");
    expect(node["three"], 3);
    expect(node["four"], 4);

    expect(() { node[null]; }, throwsA(anything));
  });

  test('arg', () {
    var node = KdlNode("node", children: [
      KdlNode("foo", arguments: [KdlString("bar")]),
      KdlNode("baz", arguments: [KdlString("qux")])
    ]);

    expect(node.arg(0), equals("bar"));
    expect(node.arg(1), equals("qux"));
    expect(node.arg("foo"), equals("bar"));
    expect(node.arg("baz"), equals("qux"));

    expect(() { node.arg(null); }, throwsA(anything));
  });

  test('args', () {
    var node = KdlNode("node", children: [
      KdlNode("foo", arguments: [KdlString("bar"), KdlString("baz")]),
      KdlNode("qux", arguments: [KdlString("norf")])
    ]);

    expect(node.args(0), equals(["bar", "baz"]));
    expect(node.args(1), equals(["norf"]));
    expect(node.args("foo"), equals(["bar", "baz"]));
    expect(node.args("qux"), equals(["norf"]));

    expect(() { node.args(null); }, throwsA(anything));
  });

  test('dashVals', () {
    var node = KdlNode("node", children: [
      KdlNode("node", children: [
        KdlNode("-", arguments: [KdlString("foo")]),
        KdlNode("-", arguments: [KdlString("bar")]),
        KdlNode("-", arguments: [KdlString("baz")])
      ])
    ]);

    expect(node.dashVals(0), equals(["foo", "bar", "baz"]));
    expect(node.dashVals("node"), equals(["foo", "bar", "baz"]));

    expect(() { node.dashVals(null); }, throwsA(anything));
  });
}
