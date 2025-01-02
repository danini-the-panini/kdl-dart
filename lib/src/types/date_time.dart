import "../document.dart";

/// ISO8601 date/time format.
class KdlDateTime extends KdlValue<DateTime> {
  /// Construct a new `KdlDateTime`
  KdlDateTime(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlDateTime`
  static KdlDateTime? convert(KdlValue value, [String type = 'date-time']) {
    if (value is! KdlString) return null;

    return KdlDateTime(DateTime.parse(value.value), type);
  }
}

/// "Time" section of ISO8601.
class KdlTime extends KdlDateTime {
  /// Construct a new `KdlTime`
  KdlTime(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlTime`
  static KdlTime? convert(KdlValue value, [String type = 'time']) {
    if (value is! KdlString) return null;

    var time = value.value;
    if (!time.startsWith('T')) time = "T$time";
    var today = DateTime.now().toString().split(' ')[0];

    return KdlTime(DateTime.parse("$today$time"), type);
  }
}

/// "Date" section of ISO8601.
class KdlDate extends KdlDateTime {
  /// Construct a new `KdlDate`
  KdlDate(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlDate`
  static KdlDate? convert(KdlValue value, [String type = 'date']) {
    if (value is! KdlString) return null;

    return KdlDate(DateTime.parse(value.value), type);
  }
}
