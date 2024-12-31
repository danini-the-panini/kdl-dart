import "../document.dart";

class KdlUUID extends KdlValue<String> {
  KdlUUID(super.value, [super.type]);
  static final regexp =
      RegExp(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");

  static call(KdlValue value, [String type = 'uuid']) {
    if (value is! KdlString) return null;

    String uuid = value.value.toLowerCase();
    if (!regexp.hasMatch(uuid)) throw "${value.value} is not a valid uuid";

    return KdlUUID(uuid, type);
  }
}
