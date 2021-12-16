import "../document.dart";
import "./irl/parser.dart";

class KdlIRLReference extends KdlValue<Uri> {
  String unicodeValue;
  String? unicodeDomain;
  String? unicodePath;
  String? unicodeSearch;
  String? unicodeHash;

  KdlIRLReference(
    Uri value,
    this.unicodeValue,
    this.unicodeDomain,
    this.unicodePath,
    this.unicodeSearch,
    this.unicodeHash,
    [String? type]
  ) : super(value, type);

  static call(KdlValue value, [String type = 'irl-reference']) {
    if (!(value is KdlString)) return null;

    var params = IRLReferenceParser(value.value).parse();

    return KdlIRLReference(
      Uri.parse(params[0]),
      params[1],
      params[2],
      params[3],
      params[4],
      params[5],
      type,
    );
  }
}

class KdlIRL extends KdlIRLReference {
  KdlIRL(
    Uri value,
    String unicodeValue,
    String? unicodeDomain,
    String? unicodePath,
    String? unicodeSearch,
    String? unicodeHash,
    [String? type]
  ) : super(
    value,
    unicodeValue,
    unicodeDomain,
    unicodePath,
    unicodeSearch,
    unicodeHash,
    type
  );

  static call(KdlValue value, [String type = 'irl-reference']) {
    if (!(value is KdlString)) return null;

    var params = IRLParser(value.value).parse();

    return KdlIRL(
      Uri.parse(params[0]),
      params[1],
      params[2],
      params[3],
      params[4],
      params[5],
      type,
    );
  }
}
