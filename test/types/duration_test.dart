import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/duration.dart';

void main() {
  test('uuid', () {
    var value = KdlDuration.convert(KdlString('P3Y6M4DT12H30M5S'))!;
    expect(value.value, equals(Duration(years: 3, months: 6, days: 4, hours: 12, minutes: 30, seconds: 5)));
    value = KdlDuration.convert(KdlString('P23DT23H'))!;
    expect(value.value, equals(Duration(days: 23, hours: 23)));
    value = KdlDuration.convert(KdlString('P4Y'))!;
    expect(value.value, equals(Duration(years: 4)));
    value = KdlDuration.convert(KdlString('PT0S'))!;
    expect(value.value, equals(Duration(seconds: 0)));
    value = KdlDuration.convert(KdlString('P0D'))!;
    expect(value.value, equals(Duration(days: 0)));
    value = KdlDuration.convert(KdlString('P0.5Y'))!;
    expect(value.value, equals(Duration(years: 0.5)));
    value = KdlDuration.convert(KdlString('P0,5Y'))!;
    expect(value.value, equals(Duration(years: 0.5)));
    value = KdlDuration.convert(KdlString('P1M'))!;
    expect(value.value, equals(Duration(months: 1)));
    value = KdlDuration.convert(KdlString('PT1M'))!;
    expect(value.value, equals(Duration(minutes: 1)));
    value = KdlDuration.convert(KdlString('P7W'))!;
    expect(value.value, equals(Duration(weeks: 7)));

    expect(() => KdlDuration.convert(KdlString('not a duration')), throwsA(anything));
  });
}
