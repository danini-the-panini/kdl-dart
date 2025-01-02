import "../document.dart";

/// RFC3986 URI Reference.
class KdlUrlReference extends KdlValue<Uri> {
  /// Constructs a new `KdlURLReference`
  KdlUrlReference(super.value, [super.type]);

  /// Converts a `KdlString` into a `KdlURLReference`
  static KdlUrlReference? convert(KdlValue value,
      [String type = 'url-reference']) {
    if (value is! KdlString) return null;

    return KdlUrlReference(Uri.parse(value.value), type);
  }
}

/// RFC3986 URI.
class KdlUrl extends KdlUrlReference {
  /// Constructs a new `KdlURL`
  KdlUrl(super.value, [super.type]);

  /// Converts a `KdlString` into a `KdlURL`
  static KdlUrl? convert(KdlValue value, [String type = 'url']) {
    if (value is! KdlString) return null;

    var uri = Uri.parse(value.value);
    if (uri.scheme == '') throw "Invalid URL: ${value.value}";

    return KdlUrl(Uri.parse(value.value), type);
  }
}
