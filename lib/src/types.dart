import "./types/uuid.dart";

class KdlTypes {
  static Map<String, Function> MAPPING = const {
    'uuid': KdlUUID.call,
  };
}
