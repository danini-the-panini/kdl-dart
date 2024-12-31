import "../document.dart";
import "./irl/parser.dart";

/// RFC3987 Internationalized Resource Identifier.
class KdlIRL extends KdlValue<Uri> {
  /// Unicode value
  String unicodeValue;

  /// Unicode domain
  String? unicodeDomain;

  /// Unicode path
  String? unicodePath;

  /// Unicode search query
  String? unicodeSearch;

  /// Unicode hash value
  String? unicodeHash;

  /// Construct a new `KdlIRL`
  KdlIRL(super.value, this.unicodeValue, this.unicodeDomain, this.unicodePath,
      this.unicodeSearch, this.unicodeHash,
      [super.type]);

  KdlIRL._from(IRL value, [String? type])
      : this(
            Uri.parse(value.asciiValue),
            value.unicodeValue,
            value.unicodeDomain,
            value.unicodePath,
            value.unicodeSearch,
            value.unicodeHash,
            type);

  /// Converts a `KdlString` into a `KdlIRL`
  static KdlIRL? call(KdlValue value, [String type = 'irl']) {
    if (value is! KdlString) return null;

    var irl = IRLParser(value.value, isReference: false).parse();

    return KdlIRL._from(irl, type);
  }
}

/// RFC3987 Internationalized Resource Identifier Reference.
class KdlIRLReference extends KdlIRL {
  /// Constructs a new `KdlIRLReference`
  KdlIRLReference(super.value, super.unicodeValue, super.unicodeDomain,
      super.unicodePath, super.unicodeSearch, super.unicodeHash,
      [super.type]);

  KdlIRLReference._from(super.value, [super.type]) : super._from();

  /// Converts a `KdlString` into a `KdlIRLReference`
  static KdlIRLReference? call(KdlValue value, [String type = 'irl-reference']) {
    if (value is! KdlString) return null;

    var irl = IRLParser(value.value).parse();

    return KdlIRLReference._from(irl, type);
  }
}
