import "../document.dart";

class KdlRegex extends KdlValue<RegExp> {
  KdlRegex(RegExp value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'regex']) {
    if (!(value is KdlString)) return null;

    return KdlRegex(RegExp(value.value), type);
  }
}
