import "../document.dart";
import "./url_template/parser.dart";

/// RFC6570 URI Template.
class KdlUrlTemplate extends KdlValue<UrlTemplate> {
  /// Construct a new `KdlURLTemplate`
  KdlUrlTemplate(super.value, [super.type]);

  /// Convert a `KdlString` into a `KdlURLTemplate`
  static KdlUrlTemplate? convert(KdlValue value, [String type = 'url-emplate']) {
    if (value is! KdlString) return null;

    var template = UrlTemplateParser(value.value).parse();

    return KdlUrlTemplate(template, type);
  }

  /// Expand the template into a Uri using the given values
  Uri expand(values) => value.expand(values);
}
