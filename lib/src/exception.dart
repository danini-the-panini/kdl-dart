class KdlException implements Exception {
  String message;
  KdlException(this.message);
  String toString() => "KdlException: $message";
}

class KdlVersionMismatchException extends KdlException {
  int version;
  int parserVersion;
  KdlVersionMismatchException(this.version, this.parserVersion)
      : super("Version mismatch, document specified v${version}, " +
            "but this is a v${parserVersion} parser");
}

class KdlParseException extends KdlException {
  String message;
  int? line;
  int? column;
  KdlParseException(this.message, [this.line = null, this.column = null]) : super(message);

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
