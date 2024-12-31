import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/irl.dart';

void main() {
  test('irl', () {
    var value = KdlIRL.call(KdlString('https://bücher.example/foo/Ῥόδος'))!;
    expect(value.value, equals(Uri.parse('https://xn--bcher-kva.example/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82')));
    expect(value.unicodeValue, equals('https://bücher.example/foo/Ῥόδος'));
    value = KdlIRL.call(KdlString('https://xn--bcher-kva.example/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82'))!;
    expect(value.value, equals(Uri.parse('https://xn--bcher-kva.example/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82')));
    expect(value.unicodeValue, equals('https://bücher.example/foo/Ῥόδος'));
    value = KdlIRL.call(KdlString('https://bücher.example/foo/Ῥόδος?🌈=✔️#🦄'))!;
    expect(value.value, equals(Uri.parse('https://xn--bcher-kva.example/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82?%F0%9F%8C%88=%E2%9C%94%EF%B8%8F#%F0%9F%A6%84')));
    expect(value.unicodeValue, equals('https://bücher.example/foo/Ῥόδος?🌈=✔️#🦄'));

    expect(() => KdlIRL.call(KdlString('not a url')), throwsA(anything));
    expect(() => KdlIRL.call(KdlString('/reference/to/something')), throwsA(anything));
  });

  test('irl reference', () {
    var value = KdlIRLReference.call(KdlString('https://bücher.example/foo/Ῥόδος'))!;
    expect(value.value, equals(Uri.parse('https://xn--bcher-kva.example/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82')));
    expect(value.unicodeValue, equals('https://bücher.example/foo/Ῥόδος'));
    value = KdlIRLReference.call(KdlString('https://xn--bcher-kva.example/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82'))!;
    expect(value.value, equals(Uri.parse('https://xn--bcher-kva.example/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82')));
    expect(value.unicodeValue, equals('https://bücher.example/foo/Ῥόδος'));
    value = KdlIRLReference.call(KdlString('https://bücher.example/foo/Ῥόδος?🌈=✔️#🦄'))!;
    expect(value.value, equals(Uri.parse('https://xn--bcher-kva.example/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82?%F0%9F%8C%88=%E2%9C%94%EF%B8%8F#%F0%9F%A6%84')));
    expect(value.unicodeValue, equals('https://bücher.example/foo/Ῥόδος?🌈=✔️#🦄'));
    value = KdlIRLReference.call(KdlString('/foo/Ῥόδος'))!;
    expect(value.value, equals(Uri.parse('/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82')));
    expect(value.unicodeValue, equals('/foo/Ῥόδος'));
    value = KdlIRLReference.call(KdlString('/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82'))!;
    expect(value.value, equals(Uri.parse('/foo/%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82')));
    expect(value.unicodeValue, equals('/foo/Ῥόδος'));

    expect(() => KdlIRLReference.call(KdlString('not a url')), throwsA(anything));
  });
}
