import "../document.dart";

class KdlDateTime extends KdlValue<DateTime> {
  KdlDateTime(super.value, [super.type]);

  static call(KdlValue value, [String type = 'date-time']) {
    if (value is! KdlString) return null;

    return KdlDateTime(DateTime.parse(value.value), type);
  }
}

class KdlTime extends KdlDateTime {
  KdlTime(super.value, [super.type]);

  static call(KdlValue value, [String type = 'time']) {
    if (value is! KdlString) return null;

    var time = value.value;
    if (!time.startsWith('T')) time = "T$time";
    var today = DateTime.now().toString().split(' ')[0];

    return KdlTime(DateTime.parse("$today$time"), type);
  }
}

class KdlDate extends KdlDateTime {
  KdlDate(super.value, [super.type]);

  static call(KdlValue value, [String type = 'date']) {
    if (value is! KdlString) return null;

    return KdlDate(DateTime.parse(value.value), type);
  }
}
