# KDL

[![Actions Status](https://github.com/jellymann/kdl-dart/workflows/Dart/badge.svg)](https://github.com/jellymann/kdl-dart/actions)

This is a Dart implementation of the [KDL Document Language](https://kdl.dev)

## Usage

```dart
import 'package:kdl/kdl.dart';

main() {
  var document = Kdl.parseDocument(someString);
}
```

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

Bug reports and pull requests are welcome on GitHub at https://github.com/jellymann/kdl-dart.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
