import "../document.dart";
import "./url_template/parser.dart";

class KdlURLTemplate extends KdlValue<URLTemplate> {
  KdlURLTemplate(URLTemplate value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'url-emplate']) {
    if (!(value is KdlString)) return null;

    var template = URLTemplateParser(value.value).parse();

    return KdlURLTemplate(template, type);
  }

  Uri expand(values) => value.expand(values);
}
