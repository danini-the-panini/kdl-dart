import "../document.dart";

/// RFC4122 UUID.
class KdlUuid extends KdlValue<String> {
  /// Consutrct a new `KdlUUID`
  KdlUuid(super.value, [super.type]);
  static final _regexp =
      RegExp(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");

  /// Convert a `KdlString` into a `KdlUUID`
  static KdlUuid? convert(KdlValue value, [String type = 'uuid']) {
    if (value is! KdlString) return null;

    String uuid = value.value.toLowerCase();
    if (!_regexp.hasMatch(uuid)) throw "${value.value} is not a valid uuid";

    return KdlUuid(uuid, type);
  }
}
