import "../document.dart";
import "./duration/iso8601_parser.dart";

/// Represents a ISO8601 duration
class ISODuration {
  /// Number of years
  num years;

  /// Number of months
  num months;

  /// Number of weeks
  num weeks;

  /// Number of days
  num days;

  /// Nubmer of hours
  num hours;

  /// Number of minutes
  num minutes;

  /// Number of seconds
  num seconds;

  /// Construct a new duration, defaulting to 0 seconds
  ISODuration({
    this.years = 0,
    this.months = 0,
    this.weeks = 0,
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
  });

  /// Construct a new duration from a map of parts
  ISODuration.fromParts(Map<String, num> parts)
      : years = parts['years'] ?? 0,
        months = parts['months'] ?? 0,
        weeks = parts['weeks'] ?? 0,
        days = parts['days'] ?? 0,
        hours = parts['hours'] ?? 0,
        minutes = parts['minutes'] ?? 0,
        seconds = parts['seconds'] ?? 0;

  @override
  bool operator ==(other) =>
      other is ISODuration &&
      other.years == years &&
      other.months == months &&
      other.weeks == weeks &&
      other.days == days &&
      other.hours == hours &&
      other.minutes == minutes &&
      other.seconds == seconds;

  @override
  int get hashCode =>
      [years, months, weeks, days, hours, minutes, seconds].hashCode;

  @override
  String toString() =>
      "years:$years months:$months weeks:$weeks days:$days hours:$hours minutes:$minutes seconds:$seconds";
}

/// ISO8601 duration format.
class KdlDuration extends KdlValue<ISODuration> {
  /// Construct a new `KdlDuration`
  KdlDuration(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlDuration`
  static KdlDuration? call(KdlValue value, [String type = 'duration']) {
    if (value is! KdlString) return null;

    var parts = ISO8601DurationParser(value.value).parse();

    return KdlDuration(ISODuration.fromParts(parts), type);
  }
}
