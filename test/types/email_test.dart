import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/email.dart';

void main() {
  test('email', () {
    var value = KdlEmail.call(KdlString('danielle@example.com'))!;
    expect(value.value, equals('danielle@example.com'));
    expect(value.local, equals('danielle'));
    expect(value.domain, equals('example.com'));

    expect(() => KdlEmail.call(KdlString('not an email')), throwsA(anything));
  });

  var validEmails = [
    ['simple@example.com', 'simple', 'example.com'],
    ['very.common@example.com', 'very.common', 'example.com'],
    ['disposable.style.email.with+symbol@example.com', 'disposable.style.email.with+symbol', 'example.com'],
    ['other.email-with-hyphen@example.com', 'other.email-with-hyphen', 'example.com'],
    ['fully-qualified-domain@example.com', 'fully-qualified-domain', 'example.com'],
    ['user.name+tag+sorting@example.com', 'user.name+tag+sorting', 'example.com'],
    ['x@example.com', 'x', 'example.com'],
    ['example-indeed@strange-example.com', 'example-indeed', 'strange-example.com'],
    ['test/test@test.com', 'test/test', 'test.com'],
    ['admin@mailserver1', 'admin', 'mailserver1'],
    ['example@s.example', 'example', 's.example'],
    ['" "@example.org', ' ', 'example.org'],
    ['"john..doe"@example.org', 'john..doe', 'example.org'],
    ['mailhost!username@example.org', 'mailhost!username', 'example.org'],
    ['user%example.com@example.org', 'user%example.com', 'example.org'],
    ['user-@example.org', 'user-', 'example.org'],
  ];

  test('valid emails', () {
    for (var testCase in validEmails) {
      var value = KdlEmail.call(KdlString(testCase[0]))!;
      expect(value.value, equals(testCase[0]));
      expect(value.local, equals(testCase[1]));
      expect(value.domain, equals(testCase[2]));
    }
  });

  var invalidEmails = [
    'Abc.example.com',
    'A@b@c@example.com',
    'a"b(c)d,e:f;g<h>i[j\\k]l@example.com',
    'just"not"right@example.com',
    'this is"not\\allowed@example.com',
    'this\\ still\\"not\\allowed@example.com',
    '1234567890123456789012345678901234567890123456789012345678901234+x@example.com',
    '-some-user-@-example-.com',
    'QA🦄CHOCOLATE🌈@test.com',
  ];

  test('invalid emails', () {
    for (var email in invalidEmails) {
      expect(() => KdlEmail.call(KdlString(email)), throwsA(anything));
    }
  });

  test('idn email', () {
    var value = KdlIDNEmail.call(KdlString('🌈@xn--9ckb.com'))!;
    expect(value.value, equals('🌈@xn--9ckb.com'));
    expect(value.unicodeValue, equals('🌈@ツッ.com'));
    expect(value.local, equals('🌈'));
    expect(value.unicodeDomain, equals('ツッ.com'));
    expect(value.domain, equals('xn--9ckb.com'));
    value = KdlIDNEmail.call(KdlString('🌈@ツッ.com'))!;
    expect(value.value, equals('🌈@xn--9ckb.com'));
    expect(value.unicodeValue, equals('🌈@ツッ.com'));
    expect(value.local, equals('🌈'));
    expect(value.unicodeDomain, equals('ツッ.com'));
    expect(value.domain, equals('xn--9ckb.com'));

    expect(() => KdlIDNEmail.call(KdlString('not an email')), throwsA(anything));
  });
}
