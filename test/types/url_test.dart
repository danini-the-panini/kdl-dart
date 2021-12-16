import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/url.dart';

void main() {
  test('url', () {
    expect(KdlURL.call(KdlString('https://www.example.com/foo/bar')).value,
      equals(Uri.parse('https://www.example.com/foo/bar')));

    expect(() => KdlURL.call(KdlString('/reference/to/something')), throwsA(anything));
  });

  test('url reference', () {
    expect(KdlURLReference.call(KdlString('https://www.example.com/foo/bar')).value,
      equals(Uri.parse('https://www.example.com/foo/bar')));
    expect(KdlURLReference.call(KdlString('/foo/bar')).value,
      equals(Uri.parse('/foo/bar')));
  });
}
