import "../document.dart";
import "./url_template/parser.dart";

/// RFC6570 URI Template.
class KdlURLTemplate extends KdlValue<URLTemplate> {
  /// Construct a new `KdlURLTemplate`
  KdlURLTemplate(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlURLTemplate`
  static KdlURLTemplate? call(KdlValue value, [String type = 'url-emplate']) {
    if (value is! KdlString) return null;

    var template = URLTemplateParser(value.value).parse();

    return KdlURLTemplate(template, type);
  }

  /// Expand the template into a Uri using the given values
  Uri expand(values) => value.expand(values);
}
