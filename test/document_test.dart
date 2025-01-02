import 'package:test/test.dart';

import 'package:kdl/src/document.dart';

void main() {
  test('equals', () {
    expect(KdlDocument([]), equals(KdlDocument([])));
    expect(KdlDocument([]) == KdlDocument([]), equals(true));
  });

  test('[]', () {
    var doc = KdlDocument([
      KdlNode("foo"),
      KdlNode("bar")
    ]);

    expect(doc[0], doc.nodes[0]);
    expect(doc[1], doc.nodes[1]);
    expect(doc["foo"], doc.nodes[0]);
    expect(doc["bar"], doc.nodes[1]);

    expect(() { doc[null]; }, throwsA(anything));
  });

  test('arg', () {
    var doc = KdlDocument([
      KdlNode("foo", arguments: [KdlString("bar")]),
      KdlNode("baz", arguments: [KdlString("qux")])
    ]);

    expect(doc.arg(0), equals("bar"));
    expect(doc.arg(1), equals("qux"));
    expect(doc.arg("foo"), equals("bar"));
    expect(doc.arg("baz"), equals("qux"));

    expect(() { doc.arg(null); }, throwsA(anything));
  });

  test('args', () {
    var doc = KdlDocument([
      KdlNode("foo", arguments: [KdlString("bar"), KdlString("baz")]),
      KdlNode("qux", arguments: [KdlString("norf")])
    ]);

    expect(doc.args(0), equals(["bar", "baz"]));
    expect(doc.args(1), equals(["norf"]));
    expect(doc.args("foo"), equals(["bar", "baz"]));
    expect(doc.args("qux"), equals(["norf"]));

    expect(() { doc.args(null); }, throwsA(anything));
  });

  test('dashVals', () {
    var doc = KdlDocument([
      KdlNode("node", children: [
        KdlNode("-", arguments: [KdlString("foo")]),
        KdlNode("-", arguments: [KdlString("bar")]),
        KdlNode("-", arguments: [KdlString("baz")])
      ])
    ]);

    expect(doc.dashVals(0), equals(["foo", "bar", "baz"]));
    expect(doc.dashVals("node"), equals(["foo", "bar", "baz"]));

    expect(() { doc.dashVals(null); }, throwsA(anything));
  });
}
