import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/date_time.dart';

void main() {
  test('date time', () {
    expect(KdlDateTime.call(KdlString('2011-10-05T22:26:12-04:00')).value,
      equals(DateTime.parse('2011-10-05T22:26:12-04:00')));

    expect(() => KdlDateTime.call(KdlString('not a date time')), throwsA(anything));
  });

  test('time', () {
    var today = DateTime.now().toString().split(' ')[0];
    expect(KdlTime.call(KdlString('22:26:12')).value,
      equals(DateTime.parse("${today}T22:26:12")));
    expect(KdlTime.call(KdlString('T22:26:12Z')).value,
      equals(DateTime.parse("${today}T22:26:12Z")));
    expect(KdlTime.call(KdlString('22:26:12.000Z')).value,
      equals(DateTime.parse("${today}T22:26:12Z")));
    expect(KdlTime.call(KdlString('22:26:12-04:00')).value,
      equals(DateTime.parse("${today}T22:26:12-04:00")));

    expect(() => KdlTime.call(KdlString('not a time')), throwsA(anything));
  });

  test('date', () {
    expect(KdlDate.call(KdlString('2011-10-05')).value,
      equals(DateTime.parse('2011-10-05')));

    expect(() => KdlDate.call(KdlString('not a date')), throwsA(anything));
  });
}
