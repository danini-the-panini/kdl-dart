class KdlException implements Exception {
  String message;
  int? line;
  int? column;
  KdlException(this.message, [this.line = null, this.column = null]);

  String toString() {
    String report = "Parse Error: $message";
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
