# KDL

[![Pub Version](https://img.shields.io/pub/v/kdl)](https://pub.dev/packages/kdl)
[![Actions Status](https://github.com/danini-the-panini/kdl-dart/workflows/Dart/badge.svg)](https://github.com/jellymann/kdl-dart/actions)

This is a Dart implementation of the [KDL Document Language](https://kdl.dev)

## Usage

```dart
import 'package:kdl/kdl.dart';

main() {
  var document = KdlDocument.parse(someString);
}
```

You can optionally provide your own type annotation handlers:

```dart
KdlDocument.parse(someString, typeParsers: {
  'foo': (value, type) {
    return Foo(value.value, type: type)
  },
});
```

The foo function will be called with instances of KdlValue or KdlNode with the type annotation (foo).

Parsers are expected to take the KdlValue or KdlNode, and the type annotation itself, as arguments, and is expected to return either an instance of KdlValue or KdlNode (depending on the input type) or null to return the original value as is. Take a look at the [built in parsers](lib/src/types) as a reference.


## Run the tests

To run the full test suite:

```
dart test
```

To run a single test file:

```
dart test test/parser_test.dart
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danini-the-panini/kdl-dart.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
