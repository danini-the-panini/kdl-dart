import "../document.dart";

/// Regular expression.
class KdlRegex extends KdlValue<RegExp> {
  /// Construct a new `KdlRegex`
  KdlRegex(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlRegex`
  static KdlRegex? call(KdlValue value, [String type = 'regex']) {
    if (value is! KdlString) return null;

    return KdlRegex(RegExp(value.value), type);
  }
}
