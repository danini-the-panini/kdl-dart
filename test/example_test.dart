import 'package:kdl/src/document.dart';
import 'package:test/test.dart';
import 'dart:io';

import 'package:kdl/kdl.dart';

typedef VarArgsCallback<T> = T Function(List<dynamic> args);

class VarArgsFunction<T> {
  final VarArgsCallback<T> callback;

  VarArgsFunction(this.callback);

  T call() => callback([]);

  @override
  dynamic noSuchMethod(Invocation inv) {
    return callback(
      inv.positionalArguments,
    );
  }
}

main() {
  KdlNode? currentNode;
  KdlDocument? currentDocument;

  dynamic n = VarArgsFunction((args) {
    var argv = List.from(args);
    var block = () {};
    var kwargs = {};
    if (argv.last is Function) block = argv.removeLast();
    if (argv.last is Map) kwargs = argv.removeLast();
    var node = KdlNode(
      argv.removeAt(0),
      arguments: argv.map((e) => KdlValue.from(e)).toList(),
      properties: kwargs.map((key, value) => MapEntry(key, KdlValue.from(value)))
    );
    var previousNode = currentNode;
    currentNode = node;
    block.call();
    currentNode = previousNode;
    if (currentNode != null) {
      currentNode!.children.add(node);
    } else {
      currentDocument!.nodes.add(node);
    }
  });

  nodes(block) {
    var doc = KdlDocument([]);
    currentDocument = doc;
    block.call();
    currentDocument = null;
    return doc;
  }

  test('ci', () async {
    var string = await File('./test/kdl-org/examples/ci.kdl').readAsString();
    var doc = KdlDocument.parse(string);
    var expectedDoc = nodes(() {
      n("name", "CI");
      n("on", "push", "pull_request");
      n("env", () {
        n("RUSTFLAGS", "-Dwarnings");
      });
      n("jobs", () {
        n("fmt_and_docs", "Check fmt & build docs", () {
          n("runs-on", "ubuntu-latest");
          n("steps", () {
            n("step", { "uses": "actions/checkout@v1" });
            n("step", "Install Rust", { "uses": "actions-rs/toolchain@v1" }, () {
              n("profile", "minimal");
              n("toolchain", "stable");
              n("components", "rustfmt");
              n("override", true);
            });
            n("step", "rustfmt", () { n("run", "cargo", "fmt", "--all", "--", "--check"); });
            n("step", "docs", () { n("run", "cargo", "doc", "--no-deps"); });
          });
        });
        n("build_and_test", "Build & Test", () {
          n("runs-on", r"${{ matrix.os }}");
          n("strategy", () {
            n("matrix", () {
              n("rust", "1.46.0", "stable");
              n("os", "ubuntu-latest", "macOS-latest", "windows-latest");
            });
          });

          n("steps", () {
            n("step", { "uses": "actions/checkout@v1" });
            n("step", "Install Rust", { "uses": "actions-rs/toolchain@v1" }, () {
              n("profile", "minimal");
              n("toolchain", r"${{ matrix.rust }}");
              n("components", "clippy");
              n("override", true);
            });
            n("step", "Clippy", () { n("run", "cargo", "clippy", "--all", "--", "-D", "warnings"); });
            n("step", "Run tests", () { n("run", "cargo", "test", "--all", "--verbose"); });
            n("step", "Other Stuff", { "run": "  echo foo\n  echo bar\n  echo baz" });
          });
        });
      });
    });

    expect(doc, equals(expectedDoc));
  });

  test('cargo', () async {
    var string = await File('./test/kdl-org/examples/Cargo.kdl').readAsString();
    var doc = KdlDocument.parse(string);
    var expectedDoc = nodes(() {
      n("package", () {
        n("name", "kdl");
        n("version", "0.0.0");
        n("description", "The kdl document language");
        n("authors", "Kat Marchán <kzm@zkat.tech>");
        n("license-file", "LICENSE.md");
        n("edition", "2018");
      });
      n("dependencies", () {
        n("nom", "6.0.1");
        n("thiserror", "1.0.22");
      });
    });

    expect(doc, equals(expectedDoc));
  });

  test('nuget', () async {
    var string = await File('./test/kdl-org/examples/nuget.kdl').readAsString();
    var doc = KdlDocument.parse(string);

    expect(doc, isNotNull);
  });

  test('kdl-schema', () async {
    var string = await File('./test/kdl-org/examples/kdl-schema.kdl').readAsString();
    var doc = KdlDocument.parse(string);

    expect(doc, isNotNull);
  });

  test('website', () async {
    var string = await File('./test/kdl-org/examples/website.kdl').readAsString();
    var doc = KdlDocument.parse(string);

    expect(doc, isNotNull);
  });
}
