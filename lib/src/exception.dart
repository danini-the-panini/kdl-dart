/// Generic KDL Exception
class KdlException implements Exception {
  /// Exception message
  String message;

  /// Construct a new KDL Exception with the given message
  KdlException(this.message);

  @override
  String toString() => "KdlException: $message";
}

/// Exception thrown when attempting to parse a versioned KDL document with the
/// incorrect parser version
class KdlVersionMismatchException extends KdlException {
  /// The version of the document
  int version;

  /// The version of the parser
  int parserVersion;

  /// Construct a new KDL Version Mismatch Exception for the given document and
  /// parser versions
  KdlVersionMismatchException(this.version, this.parserVersion)
      : super("Version mismatch, document specified v$version, "
            "but this is a v$parserVersion parser");
}

/// Exception thrown when attempting to parse an invalid KDL document
class KdlParseException extends KdlException {
  /// The line number where the parse error happened
  int? line;

  /// The column where the parse error happened
  int? column;

  /// Construct a new KDL Parse Exception with the given message, and optionally
  /// the line and column numbers where the error happened
  KdlParseException(super.message, [this.line, this.column]);

  @override
  String toString() {
    String report = "KdlParseException: $message";
    if (line != null) {
      var location = line.toString();
      if (column != null) {
        location += ":$column";
      }
      report += " ($location)";
    }
    return report;
  }
}
