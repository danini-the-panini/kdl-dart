import "../document.dart";
import "./irl/parser.dart";

class KdlIRLReference extends KdlValue<Uri> {
  String unicodeValue;
  String? unicodeDomain;
  String? unicodePath;
  String? unicodeSearch;
  String? unicodeHash;

  KdlIRLReference(
    super.value,
    this.unicodeValue,
    this.unicodeDomain,
    this.unicodePath,
    this.unicodeSearch,
    this.unicodeHash,
    [super.type]
  );

  static call(KdlValue value, [String type = 'irl-reference']) {
    if (value is! KdlString) return null;

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
    super.value,
    super.unicodeValue,
    super.unicodeDomain,
    super.unicodePath,
    super.unicodeSearch,
    super.unicodeHash,
    [super.type]
  );

  static call(KdlValue value, [String type = 'irl-reference']) {
    if (value is! KdlString) return null;

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
