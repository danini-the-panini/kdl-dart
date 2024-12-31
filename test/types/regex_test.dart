import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/regex.dart';

void main() {
  test('regex', () {
    expect(KdlRegex.call(KdlString('asdf'))!.value,
      equals(RegExp('asdf')));

    expect(() => KdlRegex.call(KdlString('invalid(regex]')), throwsA(anything));
  });
}
