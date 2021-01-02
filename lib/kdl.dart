import 'package:kdl/src/parser.dart';

abstract class Kdl {
  static parseDocument(String string) {
    return KdlParser().parse(string);
  }
}
