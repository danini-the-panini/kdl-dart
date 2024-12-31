import 'package:kdl/src/exception.dart';
import 'package:kdl/src/parser.dart';
import 'package:kdl/src/v1/parser.dart';

abstract class Kdl {
  static parseDocument(String string,
      {int? version = null,
      Map<String, Function> typeParsers = const {},
      bool parseTypes = true}) {
    switch (version) {
      case 1:
        return KdlV1Parser()
            .parse(string, typeParsers: typeParsers, parseTypes: parseTypes);
      case 2:
        return KdlParser()
            .parse(string, typeParsers: typeParsers, parseTypes: parseTypes);
      case null:
        try {
          return parseDocument(string,
              version: 2, typeParsers: typeParsers, parseTypes: parseTypes);
        } on KdlVersionMismatchException catch (e) {
          return parseDocument(string,
              version: e.version,
              typeParsers: typeParsers,
              parseTypes: parseTypes);
        } on KdlParseException {
          return parseDocument(string,
              version: 1, typeParsers: typeParsers, parseTypes: parseTypes);
        }
      default:
        throw KdlException("Unsupported version $version, supported versions are 1 or 2");
    }
  }
}
