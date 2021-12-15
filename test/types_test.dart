
import 'package:test/test.dart';

import 'package:kdl/src/parser.dart';
import 'package:kdl/src/types/uuid.dart';

void main() {
  late KdlParser parser;

  setUp(() {
    parser = KdlParser();
  });

  test('types', () {
    var doc = parser.parse("""
node (uuid)"f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
""".trim());

    var i = 0;
    expect(doc.nodes[0].arguments[i++], isA<KdlUUID>());
  });
}
