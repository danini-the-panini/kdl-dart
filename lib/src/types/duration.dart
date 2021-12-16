import "../document.dart";
import "./duration/iso8601_parser.dart";

class ISODuration {
  num years;
  num months;
  num weeks;
  num days;
  num hours;
  num minutes;
  num seconds;

  ISODuration({
    this.years = 0,
    this.months = 0,
    this.weeks = 0,
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
  });

  ISODuration.fromParts(Map<String, num> parts) :
    years = parts['years'] ?? 0,
    months = parts['months'] ?? 0,
    weeks = parts['weeks'] ?? 0,
    days = parts['days'] ?? 0,
    hours = parts['hours'] ?? 0,
    minutes = parts['minutes'] ?? 0,
    seconds = parts['seconds'] ?? 0;

  @override
  bool operator ==(other) => other is ISODuration &&
    other.years == years &&
    other.months == months &&
    other.weeks == weeks &&
    other.days == days &&
    other.hours == hours &&
    other.minutes == minutes &&
    other.seconds == seconds;

  @override
  String toString() => "years:$years months:$months weeks:$weeks days:$days hours:$hours minutes:$minutes seconds:$seconds";
}

class KdlDuration extends KdlValue<ISODuration> {
  KdlDuration(ISODuration value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'duration']) {
    if (!(value is KdlString)) return null;

    var parts = ISO8601DurationParser(value.value).parse();

    return KdlDuration(ISODuration.fromParts(parts), type);
  }
}
