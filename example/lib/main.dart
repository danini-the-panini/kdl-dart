import 'package:kdl/kdl.dart';

main() {
  var document = KdlDocument.parse("""
    node 1 2 3 "foo" bar="baz" {
      childNode 1
      childNode 2
    }
  """);

  print(document.toString());
}
