import "../document.dart";

class KdlURLReference extends KdlValue<Uri> {
  KdlURLReference(super.value, [super.type]);

  static call(KdlValue value, [String type = 'url-reference']) {
    if (value is! KdlString) return null;

    return KdlURLReference(Uri.parse(value.value), type);
  }
}

class KdlURL extends KdlURLReference {
  KdlURL(super.value, [super.type]);

  static call(KdlValue value, [String type = 'url']) {
    if (value is! KdlString) return null;

    var uri = Uri.parse(value.value);
    if (uri.scheme == '') throw "Invalid URL: ${value.value}";

    return KdlURL(Uri.parse(value.value), type);
  }
}
