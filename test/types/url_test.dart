import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/url.dart';

void main() {
  test('url', () {
    expect(KdlUrl.convert(KdlString('https://www.example.com/foo/bar'))!.value,
      equals(Uri.parse('https://www.example.com/foo/bar')));

    expect(() => KdlUrl.convert(KdlString('/reference/to/something')), throwsA(anything));
  });

  test('url reference', () {
    expect(KdlUrlReference.convert(KdlString('https://www.example.com/foo/bar'))!.value,
      equals(Uri.parse('https://www.example.com/foo/bar')));
    expect(KdlUrlReference.convert(KdlString('/foo/bar'))!.value,
      equals(Uri.parse('/foo/bar')));
  });
}
