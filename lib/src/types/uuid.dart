import "../document.dart";

class KdlUUID extends KdlValue<String> {
  KdlUUID(String value, [String? type]) : super(value, type);
  static var _RGX = RegExp(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");

  static call(KdlValue value, [String type = 'uuid']) {
    if (!(value is KdlString)) return null;

    String uuid = value.value.toLowerCase();
    if (!_RGX.hasMatch(uuid)) throw "${value.value} is not a valid uuid";

    return KdlUUID(uuid, type);
  }
}
