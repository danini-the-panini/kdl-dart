import 'package:test/test.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:kdl/src/v1/parser.dart';
import 'package:kdl/src/exception.dart';

void main() {
  KdlV1Parser parser = KdlV1Parser();

  var excludedTests = ['escline_comment_node'];

  var testCasesPath = p.join(
      Directory.current.path, 'test', 'v1', 'kdl-org', 'tests', 'test_cases');
  var inputsDir = Directory(p.join(testCasesPath, 'input'));
  var expectedPath = p.join(testCasesPath, 'expected_kdl');
  for (var entry in inputsDir.listSync()) {
    if (entry is Directory) continue;
    var inputFile = (entry as File);
    var inputName = p.basenameWithoutExtension(inputFile.path);
    if (excludedTests.contains(inputName)) continue;
    var expectedFile = File(p.join(expectedPath, "$inputName.kdl"));
    if (expectedFile.existsSync()) {
      test("$inputName matches expected output", () async {
        var input = await inputFile.readAsString();
        var expected = await expectedFile.readAsString();
        expect(parser.parse(input).toString(),
            equals(parser.parse(expected).toString()));
      });
    } else {
      test("$inputName does not parse", () async {
        var input = await inputFile.readAsString();
        expect(() {
          parser.parse(input);
        }, throwsA(isA<KdlParseException>()));
      });
    }
  }
}
