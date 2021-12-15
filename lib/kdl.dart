import 'package:kdl/src/parser.dart';

abstract class Kdl {
  static parseDocument(String string, { Map<String, Function> typeParsers = const {}, bool parseTypes = true }) {
    return KdlParser().parse(string, typeParsers: typeParsers, parseTypes: parseTypes);
  }
}
