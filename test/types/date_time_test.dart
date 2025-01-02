import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/date_time.dart';

void main() {
  test('date time', () {
    expect(KdlDateTime.convert(KdlString('2011-10-05T22:26:12-04:00'))!.value,
      equals(DateTime.parse('2011-10-05T22:26:12-04:00')));

    expect(() => KdlDateTime.convert(KdlString('not a date time')), throwsA(anything));
  });

  test('time', () {
    var today = DateTime.now().toString().split(' ')[0];
    expect(KdlTime.convert(KdlString('22:26:12'))!.value,
      equals(DateTime.parse("${today}T22:26:12")));
    expect(KdlTime.convert(KdlString('T22:26:12Z'))!.value,
      equals(DateTime.parse("${today}T22:26:12Z")));
    expect(KdlTime.convert(KdlString('22:26:12.000Z'))!.value,
      equals(DateTime.parse("${today}T22:26:12Z")));
    expect(KdlTime.convert(KdlString('22:26:12-04:00'))!.value,
      equals(DateTime.parse("${today}T22:26:12-04:00")));

    expect(() => KdlTime.convert(KdlString('not a time')), throwsA(anything));
  });

  test('date', () {
    expect(KdlDate.convert(KdlString('2011-10-05'))!.value,
      equals(DateTime.parse('2011-10-05')));

    expect(() => KdlDate.convert(KdlString('not a date')), throwsA(anything));
  });
}
