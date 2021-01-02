import 'package:test/test.dart';

import '../lib/src/document.dart';

void main() {
  test('equals', () {
    expect(KdlDocument([]), equals(KdlDocument([])));
    expect(KdlDocument([]) == KdlDocument([]), equals(true));
  });
}
