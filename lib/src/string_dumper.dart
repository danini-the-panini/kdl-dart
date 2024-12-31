import 'package:kdl/src/tokenizer.dart';

class StringDumper {
  String string = '';

  StringDumper(this.string);

  String dump() {
    if (_isBareIdentifier()) return string;

    return "\"${string.runes.map(_escape).join('')}\"";
  }

  String _escape(int rune) {
    switch (rune) {
      case 10:
        return "\\n";
      case 13:
        return "\\r";
      case 9:
        return "\\t";
      case 92:
        return "\\\\";
      case 34:
        return "\\\"";
      case 8:
        return "\\b";
      case 12:
        return "\\f";
      default:
        return String.fromCharCode(rune);
    }
  }

  static final forbidden = [
    ...KdlTokenizer.symbols.keys.map((e) => e.runes.single),
    ...KdlTokenizer.whitespace.map((e) => e.runes.single),
    ...KdlTokenizer.newlines.map((e) => e.runes.single),
    ..."()[]/\\\"#".runes,
    ...List.generate(0x20, (e) => e),
  ];

  bool _isBareIdentifier() {
    if ([
          '',
          'true',
          'false',
          'null',
          'inf',
          '-inf',
          'nan',
          '#true',
          '#false',
          '#null',
          '#inf',
          '#-inf',
          '#nan'
        ].contains(string) ||
        RegExp(r"^\.?\d").hasMatch(string)) {
      return false;
    }

    return !string.runes.any((c) => forbidden.contains(c));
  }
}
