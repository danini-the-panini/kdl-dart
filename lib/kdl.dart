import 'package:kdl/kdl.dart';

export 'package:kdl/src/document.dart';

///
abstract class Kdl {
  @Deprecated("Use KdlDocument.parse instead")
  static parseDocument(String string,
      {Map<String, Function> typeParsers = const {}, bool parseTypes = true}) {
    return KdlDocument.parse(string,
        typeParsers: typeParsers, parseTypes: parseTypes);
  }
}
