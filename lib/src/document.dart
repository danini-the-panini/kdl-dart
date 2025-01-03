import 'dart:collection';

import 'package:kdl/src/exception.dart';
import 'package:kdl/src/parser.dart';
import 'package:big_decimal/big_decimal.dart';
import 'package:kdl/src/tokenizer.dart';

_sameNodes(List<KdlNode> nodes, List<KdlNode> otherNodes) {
  if (nodes.length != otherNodes.length) return false;

  for (var i = 0; i < nodes.length; i++) {
    if (nodes[i] != otherNodes[i]) return false;
  }

  return true;
}

/// KDL Root node
class KdlDocument with IterableMixin<KdlNode> {
  /// Top level nodes
  List<KdlNode> nodes = [];

  /// Parse a KDL document
  ///
  /// By default, attempts to parse v2 syntax, and falls back to v1 if that
  /// fails. You can override this behaviour by explicitely passing `version`.
  ///
  /// By default, parses well-known types as specified by [defaultValueTypes].
  /// You can turn this off by passing `parseTypes: false`. You can also add
  /// your own custom types by passing `valueTypes` and `nodeTypes`.
  static KdlDocument parse(String string,
      {int? version,
      Map<String, KdlTypeParser<KdlValue>> valueTypes = const {},
      Map<String, KdlTypeParser<KdlNode>> nodeTypes = const {},
      bool parseTypes = true}) {
    switch (version) {
      case 1:
        return KdlV1Parser().parse(string,
            valueTypes: valueTypes,
            nodeTypes: nodeTypes,
            parseTypes: parseTypes);
      case 2:
        return KdlParser().parse(string,
            valueTypes: valueTypes,
            nodeTypes: nodeTypes,
            parseTypes: parseTypes);
      case null:
        try {
          return parse(string,
              version: 2,
              valueTypes: valueTypes,
              nodeTypes: nodeTypes,
              parseTypes: parseTypes);
        } on KdlVersionMismatchException catch (e) {
          return parse(string,
              version: e.version,
              valueTypes: valueTypes,
              nodeTypes: nodeTypes,
              parseTypes: parseTypes);
        } on KdlParseException {
          return parse(string,
              version: 1, valueTypes: valueTypes, nodeTypes: nodeTypes);
        }
      default:
        throw KdlException(
            "Unsupported version $version, supported versions are 1 or 2");
    }
  }

  /// Create a new KdlDocument with the given nodes
  KdlDocument([List<KdlNode>? initialNodes]) {
    nodes = initialNodes ?? [];
  }

  /// Return the value of the first arg of the requested node
  arg(key) {
    return this[key].arguments.first.value;
  }

  /// Return the argument values of the requested node
  Iterable<dynamic> args(key) {
    return this[key].arguments.map((arg) => arg.value);
  }

  /// Return the first argument value of each node named '-' that is a child of
  /// the requested node
  Iterable<dynamic> dashVals(key) {
    return this[key]
        .children
        .where((node) => node.name == "-")
        .map((node) => node.arguments.first)
        .map((arg) => arg.value);
  }

  /// Request a node. If key is an `int`, return the node by index. If the key is
  /// a `String`, return the first node with that name
  KdlNode operator [](key) {
    if (key is int) {
      return nodes[key];
    } else if (key is String) {
      return nodes.firstWhere((node) => node.name == key);
    } else {
      throw ArgumentError("document can only be indexed with Int/String");
    }
  }

  @override
  bool operator ==(other) =>
      other is KdlDocument && _sameNodes(nodes, other.nodes);

  @override
  int get hashCode => nodes.hashCode;

  @override
  Iterator<KdlNode> get iterator => nodes.iterator;

  @override
  String toString() {
    return "${nodes.map((e) => e.toString()).join("\n")}\n";
  }
}

/// Function signature for converting `KdlValue` and `KdlNode` into custom types.
/// Return `null` to skip parsing and keep the original value.
typedef KdlTypeParser<T> = T? Function(T, String type);

/// A KDL node. Nodes can have positional arguments, key=value properties, and
/// other nodes as children.
class KdlNode with IterableMixin<KdlNode> {
  /// The name of the node
  String name = '';

  /// Optional type annotation
  String? type;

  /// Child nodes
  List<KdlNode> children = [];

  /// Positional arguments
  List<KdlValue> arguments = [];

  /// Key=value properties
  Map<String, KdlValue> properties = {};

  /// Construct a new KDL node
  KdlNode(this.name,
      {List<KdlNode>? children,
      List<KdlValue>? arguments,
      Map<String, KdlValue>? properties,
      this.type}) {
    this.children = children ?? [];
    this.arguments = arguments ?? [];
    this.properties = properties ?? {};
  }

  /// Returns true if this node has at least one child node
  bool get hasChildren {
    return children.isNotEmpty;
  }

  /// Request a child node by key. If key is an `int`, return the node by index.
  /// If the key is a `String`, return the first node with that name
  KdlNode child(key) {
    if (key is int) {
      return children[key];
    } else if (key is String) {
      return children.firstWhere((node) => node.name == key);
    } else {
      throw ArgumentError("node can only be indexed with Int/String");
    }
  }

  /// Return the value of the first arg of the requested child node
  arg(key) {
    return child(key).arguments.first.value;
  }

  /// Return the argument values of the requested child node
  args(key) {
    return child(key).arguments.map((arg) => arg.value);
  }

  /// Return the first argument value of each node named '-' that is a
  /// child of the requested child node
  dashVals(key) {
    return child(key)
        .children
        .where((node) => node.name == "-")
        .map((node) => node.arguments.first)
        .map((arg) => arg.value);
  }

  /// If `key` is an `int`, return the value of the appropriate positional
  /// argument. If `key` is a `String`, return the value of the matching
  /// property
  operator [](key) {
    if (key is int) {
      return arguments[key].value;
    } else if (key is String) {
      return properties[key]?.value;
    } else {
      throw ArgumentError("node can only be indexed with Int/String");
    }
  }

  @override
  bool operator ==(other) =>
      other is KdlNode &&
      name == other.name &&
      _sameNodes(children, other.children) &&
      _sameArguments(other.arguments) &&
      _sameProperties(other.properties);

  @override
  int get hashCode => [children, arguments, properties].hashCode;

  @override
  Iterator<KdlNode> get iterator => children.iterator;

  @override
  String toString() {
    return _toStringWithIndentation(0);
  }

  /// Sets the type of a node. If a `parser` is provided, calls the function
  /// with the node and type and returns the result if any, otherwise returns
  /// `this`
  KdlNode asType(String type, [KdlTypeParser<KdlNode>? parser]) {
    if (parser == null) {
      this.type = type;
      return this;
    }

    var result = parser(this, type);

    if (result == null) return asType(type);

    return result;
  }

  String _toStringWithIndentation(int indentation) {
    String indent = "    " * indentation;
    String typeStr = type != null ? "(${_idToString(type!)})" : "";
    String s = "$indent$typeStr${_idToString(name)}";
    if (arguments.isNotEmpty) {
      s += " ${arguments.map((a) => a.toString()).join(' ')}";
    }
    if (properties.isNotEmpty) {
      s +=
          " ${properties.entries.map((e) => "${_idToString(e.key)}=${e.value}").join(' ')}";
    }
    if (children.isNotEmpty) {
      var childrenStr = children
          .map((e) => e._toStringWithIndentation(indentation + 1))
          .join("\n");
      s += " {\n$childrenStr\n$indent}";
    }
    return s;
  }

  _sameArguments(List<KdlValue> otherArgs) {
    if (arguments.length != otherArgs.length) return false;

    for (var i = 0; i < arguments.length; i++) {
      if (arguments[i] != otherArgs[i]) return false;
    }

    return true;
  }

  _sameProperties(Map<String, KdlValue> otherProps) {
    if (properties.length != otherProps.length) return false;

    return properties.entries
        .every((element) => otherProps[element.key] == element.value);
  }

  _idToString(String id) {
    return _StringDumper(id).dump();
  }
}

/// Base class for all KDL Value types
abstract class KdlValue<T> {
  /// Internally stored value
  late T value;

  /// Optional type annotation
  String? type;

  /// Construct a new KDL Value with a given internal value and optional type
  KdlValue(this.value, [this.type]);

  /// Create the appropriate KDL Value from the given native value
  static KdlValue from(v, [String? type]) {
    if (v is String) return KdlString(v, type);
    if (v is int) return KdlInt(v, type);
    if (v is double) return KdlDouble(v, type);
    if (v is BigDecimal) return KdlBigDecimal(v, type);
    if (v is bool) return KdlBool(v, type);
    if (v == null) {
      if (type == null) {
        return KdlNull();
      } else {
        return KdlNull.withType(type);
      }
    }

    throw "No KDL value for $v";
  }

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(other) {
    if (other is KdlValue) return value == other.value;

    return value == other;
  }

  @override
  String toString() {
    if (type == null) {
      return _stringifyValue();
    } else {
      return "(${_StringDumper(type!).dump()})${_stringifyValue()}";
    }
  }

  /// Sets the type of a value. If a `parser` is provided, calls the function
  /// with the value and type and returns the result if any, otherwise returns
  /// `this`
  KdlValue asType(String type, [KdlTypeParser<KdlValue>? parser]) {
    if (parser == null) {
      this.type = type;
      return this;
    }

    var result = parser(this, type);
    if (result == null) return asType(type);

    return result;
  }

  String _stringifyValue() {
    return value.toString();
  }
}

/// KDL Value wrapping a `String`
class KdlString extends KdlValue<String> {
  /// Construct a new KDL String
  KdlString(super.value, [super.type]);

  @override
  String _stringifyValue() {
    return _StringDumper(value).dump();
  }
}

/// KDL Value wrapping a `BigDecimal`
class KdlBigDecimal extends KdlValue<BigDecimal> {
  /// Construct a new KDL BigDecimal
  KdlBigDecimal(super.value, [super.type]);

  /// Construct a new KDL BigDecimal using a native `num`
  KdlBigDecimal.from(num value, [String? type])
      : super(BigDecimal.parse(value.toString()), type);

  @override
  bool operator ==(other) {
    if (other is KdlBigDecimal) return value == other.value;
    return value == other;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String _stringifyValue() {
    return value.toString().toUpperCase();
  }
}

/// KDL Value wrapping a `double`
class KdlDouble extends KdlValue<double> {
  /// Construct a new KDL Double
  KdlDouble(super.value, [super.type]);

  @override
  bool operator ==(other) {
    var otherValue = other;
    if (other is KdlValue) otherValue = other.value;

    if (value.isNaN && otherValue is double && otherValue.isNaN) return true;
    return value == otherValue;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String _stringifyValue() {
    if (value.isNaN) return '#nan';
    if (value == double.infinity) return '#inf';
    if (value == -double.infinity) return '#-inf';

    return value.toString().toUpperCase();
  }
}

/// KDL Value wrapping integer types
class KdlInt<I> extends KdlValue<I> {
  /// Construct a new KDL Int
  KdlInt(super.value, [super.type]);

  @override
  bool operator ==(other) => other is KdlInt && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// KDL Value wrapping a `bool`
class KdlBool extends KdlValue<bool> {
  /// Construct a new KDL Bool
  KdlBool(super.value, [super.type]);

  @override
  bool operator ==(other) => other is KdlBool && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String _stringifyValue() {
    return value ? '#true' : '#false';
  }
}

/// KDL Value representing `null`
class KdlNull extends KdlValue<Null> {
  static final KdlNull _singleton = KdlNull._internal();

  /// Return the untyped singleton KDL Null
  factory KdlNull() {
    return _singleton;
  }

  KdlNull._internal() : super(null, null);

  /// Construct a new KDL Null with a type annotation
  KdlNull.withType(String type) : super(null, type);

  @override
  bool operator ==(other) => other is KdlNull;

  @override
  int get hashCode => null.hashCode;

  @override
  String _stringifyValue() {
    return '#null';
  }

  /// Returns a new KDL Null with the given type. If a parser is passed in,
  /// calls it with the current value and returns the result if any, otherwise
  /// falls back to creating a new Null with the given type annotation.
  @override
  KdlValue asType(String type, [KdlTypeParser<KdlValue>? parser]) {
    if (parser == null) {
      return KdlNull.withType(type);
    }

    var result = parser(this, type);
    if (result == null) return asType(type);

    return result;
  }
}

class _StringDumper {
  final String _string;

  _StringDumper(this._string);

  String dump() {
    if (_isBareIdentifier()) return _string;

    return "\"${_string.codeUnits.map(_escape).join('')}\"";
  }

  String _escape(int code) {
    switch (code) {
      case 10:
        return "\\n";
      case 13:
        return "\\r";
      case 9:
        return "\\t";
      case 92:
        return "\\\\";
      case 34:
        return "\\\"";
      case 8:
        return "\\b";
      case 12:
        return "\\f";
      default:
        return String.fromCharCode(code);
    }
  }

  static final forbidden = [
    ...KdlTokenizer.symbols.keys.map((e) => e.codeUnits.single),
    ...KdlTokenizer.whitespace.map((e) => e.codeUnits.single),
    ...KdlTokenizer.newlines.map((e) => e.codeUnits.single),
    ..."()[]/\\\"#".codeUnits,
    ...List.generate(0x20, (e) => e),
  ];

  bool _isBareIdentifier() {
    if ([
          '',
          'true',
          'false',
          'null',
          'inf',
          '-inf',
          'nan',
          '#true',
          '#false',
          '#null',
          '#inf',
          '#-inf',
          '#nan'
        ].contains(_string) ||
        RegExp(r"^\.?\d").hasMatch(_string)) {
      return false;
    }

    return !_string.codeUnits.any((c) => forbidden.contains(c));
  }
}
