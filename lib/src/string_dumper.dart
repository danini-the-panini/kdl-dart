class StringDumper {
  String string = '';

  StringDumper(String string) {
    this.string = string;
  }

  String dump() {
    return "\"${string.runes.map(_escape).join('')}\"";
  }

  String stringifyIdentifier() {
    if (_isBareIdentifier()) {
      return string;
    } else {
      return dump();
    }
  }

  String _escape(int rune) {
    switch (rune) {
      case 10: return "\\n";
      case 13: return "\\r";
      case 9: return "\\t";
      case 92: return "\\\\";
      case 34: return "\\\"";
      case 8: return "\\b";
      case 12: return "\\f";
      default: return String.fromCharCodes([rune]);
    }
  }

  static final ESCAPE_CHARS = RegExp.escape("\\/(){}<>;[]=,\"");
  static final BARE_ID_RGX = RegExp("^([^0-9\\-+\\s${ESCAPE_CHARS}][^\\s${ESCAPE_CHARS}]*|" +
                                    "[\\-+](?!true|false|null)[^0-9\\s${ESCAPE_CHARS}][^\\s${ESCAPE_CHARS}]*)\$");
  bool _isBareIdentifier() {
    return BARE_ID_RGX.hasMatch(string);
  }
}
