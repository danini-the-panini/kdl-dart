import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/uuid.dart';

void main() {
  test('uuid', () {
    expect(KdlUuid.convert(KdlString('f81d4fae-7dec-11d0-a765-00a0c91e6bf6'))!.value,
      equals('f81d4fae-7dec-11d0-a765-00a0c91e6bf6'));
    expect(KdlUuid.convert(KdlString('F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6'))!.value,
      equals('f81d4fae-7dec-11d0-a765-00a0c91e6bf6'));

    expect(() => KdlUuid.convert(KdlString('not a uuid')), throwsA(anything));
  });
}
