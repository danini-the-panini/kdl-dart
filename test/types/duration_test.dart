import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/duration.dart';

void main() {
  test('uuid', () {
    var value = KdlDuration.call(KdlString('P3Y6M4DT12H30M5S'))!;
    expect(value.value, equals(ISODuration(years: 3, months: 6, days: 4, hours: 12, minutes: 30, seconds: 5)));
    value = KdlDuration.call(KdlString('P23DT23H'))!;
    expect(value.value, equals(ISODuration(days: 23, hours: 23)));
    value = KdlDuration.call(KdlString('P4Y'))!;
    expect(value.value, equals(ISODuration(years: 4)));
    value = KdlDuration.call(KdlString('PT0S'))!;
    expect(value.value, equals(ISODuration(seconds: 0)));
    value = KdlDuration.call(KdlString('P0D'))!;
    expect(value.value, equals(ISODuration(days: 0)));
    value = KdlDuration.call(KdlString('P0.5Y'))!;
    expect(value.value, equals(ISODuration(years: 0.5)));
    value = KdlDuration.call(KdlString('P0,5Y'))!;
    expect(value.value, equals(ISODuration(years: 0.5)));
    value = KdlDuration.call(KdlString('P1M'))!;
    expect(value.value, equals(ISODuration(months: 1)));
    value = KdlDuration.call(KdlString('PT1M'))!;
    expect(value.value, equals(ISODuration(minutes: 1)));
    value = KdlDuration.call(KdlString('P7W'))!;
    expect(value.value, equals(ISODuration(weeks: 7)));

    expect(() => KdlDuration.call(KdlString('not a duration')), throwsA(anything));
  });
}
