import "../document.dart";

/// RFC3986 URI Reference.
class KdlURLReference extends KdlValue<Uri> {
  /// Constructs a new `KdlURLReference`
  KdlURLReference(super.value, [super.type]);

  /// Converts a `KdlString` into a `KdlURLReference`
  static KdlURLReference? call(KdlValue value,
      [String type = 'url-reference']) {
    if (value is! KdlString) return null;

    return KdlURLReference(Uri.parse(value.value), type);
  }
}

/// RFC3986 URI.
class KdlURL extends KdlURLReference {
  /// Constructs a new `KdlURL`
  KdlURL(super.value, [super.type]);

  /// Converts a `KdlString` into a `KdlURL`
  static KdlURL? call(KdlValue value, [String type = 'url']) {
    if (value is! KdlString) return null;

    var uri = Uri.parse(value.value);
    if (uri.scheme == '') throw "Invalid URL: ${value.value}";

    return KdlURL(Uri.parse(value.value), type);
  }
}
