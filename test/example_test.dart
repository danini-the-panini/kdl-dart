import 'package:kdl/src/document.dart';
import 'package:test/test.dart';
import 'dart:io';

import 'package:kdl/kdl.dart';

typedef T VarArgsCallback<T>(List<dynamic> args);

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
  KdlNode currentNode = null;
  KdlDocument currentDocument = null;

  dynamic _ = VarArgsFunction((args) {
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
      currentNode.children.add(node);
    } else {
      currentDocument.nodes.add(node);
    }
  });

  var nodes = (block) {
    var doc = KdlDocument([]);
    currentDocument = doc;
    block.call();
    currentDocument = null;
    return doc;
  };

  test('ci', () async {
    print(Directory.current);
    var string = await new File('./example/ci.kdl').readAsString();
    var doc = Kdl.parseDocument(string);
    var expectedDoc = nodes(() {
      _("name", "CI");
      _("on", "push", "pull_request");
      _("env", () {
        _("RUSTFLAGS", "-Dwarnings");
      });
      _("jobs", () {
        _("fmt_and_docs", "Check fmt & build docs", () {
          _("runs-on", "ubuntu-latest");
          _("steps", () {
            _("step", { "uses": "actions/checkout@v1" });
            _("step", "Install Rust", { "uses": "actions-rs/toolchain@v1" }, () {
              _("profile", "minimal");
              _("toolchain", "stable");
              _("components", "rustfmt");
              _("override", true);
            });
            _("step", "rustfmt", { "run": "cargo fmt --all -- --check" });
            _("step", "docs", { "run": "cargo doc --no-deps" });
          });
        });
        _("build_and_test", "Build & Test", () {
          _("runs-on", r"${{ matrix.os }}");
          _("strategy", () {
            _("matrix", () {
              _("rust", "1.46.0", "stable");
              _("os", "ubuntu-latest", "macOS-latest", "windows-latest");
            });
          });

          _("steps", () {
            _("step", { "uses": "actions/checkout@v1" });
            _("step", "Install Rust", { "uses": "actions-rs/toolchain@v1" }, () {
              _("profile", "minimal");
              _("toolchain", r"${{ matrix.rust }}");
              _("components", "clippy");
              _("override", true);
            });
            _("step", "Clippy", { "run": "cargo clippy --all -- -D warnings" });
            _("step", "Run tests", { "run": "cargo test --all --verbose" });
          });
        });
      });
    });

    expect(doc, equals(expectedDoc));
  });

  test('cargo', () async {
    var string = await new File('./example/cargo.kdl').readAsString();
    var doc = Kdl.parseDocument(string);
    var expectedDoc = nodes(() {
      _("package", () {
        _("name", "kdl");
        _("version", "0.0.0");
        _("description", "kat's document language");
        _("authors", "Kat Marchán <kzm@zkat.tech>");
        _("license-file", "LICENSE.md");
        _("edition", "2018");
      });
      _("dependencies", () {
        _("nom", "6.0.1");
        _("thiserror", "1.0.22");
      });
    });

    expect(doc, equals(expectedDoc));
  });

  test('nuget', () async {
    var string = await new File('./example/nuget.kdl').readAsString();
    var doc = Kdl.parseDocument(string);

    // This file is particularly large. It would be nice to validate it, but for now
    // I'm just going to settle for making sure it parses.

    expect(doc, isNotNull);
  });
}
