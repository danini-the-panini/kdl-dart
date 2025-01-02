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

  KdlIRL._from(Irl value, [String? type])
      : this(
            Uri.parse(value.asciiValue),
            value.unicodeValue,
            value.unicodeDomain,
            value.unicodePath,
            value.unicodeSearch,
            value.unicodeHash,
            type);

  /// Converts a `KdlString` into a `KdlIRL`
  static KdlIRL? convert(KdlValue value, [String type = 'irl']) {
    if (value is! KdlString) return null;

    var irl = IrlParser(value.value, isReference: false).parse();

    return KdlIRL._from(irl, type);
  }
}

/// RFC3987 Internationalized Resource Identifier Reference.
class KdlIrlReference extends KdlIRL {
  /// Constructs a new `KdlIRLReference`
  KdlIrlReference(super.value, super.unicodeValue, super.unicodeDomain,
      super.unicodePath, super.unicodeSearch, super.unicodeHash,
      [super.type]);

  KdlIrlReference._from(super.value, [super.type]) : super._from();

  /// Converts a `KdlString` into a `KdlIRLReference`
  static KdlIrlReference? convert(KdlValue value,
      [String type = 'irl-reference']) {
    if (value is! KdlString) return null;

    var irl = IrlParser(value.value).parse();

    return KdlIrlReference._from(irl, type);
  }
}
