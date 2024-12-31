class KdlException implements Exception {
  String message;
  KdlException(this.message);
  @override
  String toString() => "KdlException: $message";
}

class KdlVersionMismatchException extends KdlException {
  int version;
  int parserVersion;
  KdlVersionMismatchException(this.version, this.parserVersion)
      : super("Version mismatch, document specified v$version, "
            "but this is a v$parserVersion parser");
}

class KdlParseException extends KdlException {
  int? line;
  int? column;
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
