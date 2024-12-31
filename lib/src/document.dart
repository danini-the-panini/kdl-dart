import 'dart:collection';

import 'package:kdl/src/exception.dart';
import 'package:kdl/src/parser.dart';
import "package:kdl/src/string_dumper.dart";
import 'package:big_decimal/big_decimal.dart';
import 'package:kdl/src/v1/parser.dart';

_sameNodes(List<KdlNode> nodes, List<KdlNode> otherNodes) {
  if (nodes.length != otherNodes.length) return false;

  for (var i = 0; i < nodes.length; i++) {
    if (nodes[i] != otherNodes[i]) return false;
  }

  return true;
}

class KdlDocument with IterableMixin<KdlNode> {
  List<KdlNode> nodes = [];

  static KdlDocument parse(String string,
      {int? version,
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
          return parse(string,
              version: 2, typeParsers: typeParsers, parseTypes: parseTypes);
        } on KdlVersionMismatchException catch (e) {
          return parse(string,
              version: e.version,
              typeParsers: typeParsers,
              parseTypes: parseTypes);
        } on KdlParseException {
          return parse(string,
              version: 1, typeParsers: typeParsers, parseTypes: parseTypes);
        }
      default:
        throw KdlException(
            "Unsupported version $version, supported versions are 1 or 2");
    }
  }

  KdlDocument(List<KdlNode> initialNodes) {
    nodes = initialNodes;
  }

  arg(key) {
    return this[key].arguments.first.value;
  }

  args(key) {
    return this[key].arguments.map((arg) => arg.value);
  }

  dashVals(key) {
    return this[key]
        .children
        .where((node) => node.name == "-")
        .map((node) => node.arguments.first)
        .map((arg) => arg.value);
  }

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

class KdlNode with IterableMixin<KdlNode> {
  String name = '';
  String? type;
  List<KdlNode> children = [];
  List<KdlValue> arguments = [];
  Map<String, KdlValue> properties = {};

  KdlNode(this.name,
      {List<KdlNode>? children,
      List<KdlValue>? arguments,
      Map<String, KdlValue>? properties,
      this.type}) {
    this.children = children ?? [];
    this.arguments = arguments ?? [];
    this.properties = properties ?? {};
  }

  bool get hasChildren {
    return children.isNotEmpty;
  }

  KdlNode child(key) {
    if (key is int) {
      return children[key];
    } else if (key is String) {
      return children.firstWhere((node) => node.name == key);
    } else {
      throw ArgumentError("node can only be indexed with Int/String");
    }
  }

  arg(key) {
    return child(key).arguments.first.value;
  }

  args(key) {
    return child(key).arguments.map((arg) => arg.value);
  }

  dashVals(key) {
    return child(key)
        .children
        .where((node) => node.name == "-")
        .map((node) => node.arguments.first)
        .map((arg) => arg.value);
  }

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

  KdlNode asType(String type, [Function? parser]) {
    if (parser == null) {
      this.type = type;
      return this;
    }

    var result = parser(this, type);

    if (result == null) return asType(type);

    if (result is! KdlNode) {
      throw "expected parser to return an instance of KdlNode, got ${result.runtimeType}";
    }

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
    return StringDumper(id).dump();
  }
}

abstract class KdlValue<T> {
  late T value;
  String? type;

  KdlValue(this.value, [this.type]);

  static KdlValue from(v, [String? type]) {
    if (v is String) return KdlString(v, type);
    if (v is int) return KdlInt(v, type);
    if (v is double) return KdlDouble(v, type);
    if (v is BigDecimal) return KdlBigDecimal(v, type);
    if (v is bool) return KdlBool(v, type);
    if (v == null) return KdlNull(type);
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
      return "(${StringDumper(type!).dump()})${_stringifyValue()}";
    }
  }

  asType(String type, [Function? parser]) {
    if (parser == null) {
      this.type = type;
      return this;
    }

    var result = parser(this, type);
    if (result == null) return asType(type);

    if (result is! KdlValue) {
      throw "expected parser to return an instance of KdlValue, got ${result.runtimeType}";
    }

    return result;
  }

  String _stringifyValue() {
    return value.toString();
  }
}

class KdlString extends KdlValue<String> {
  KdlString(super.value, [super.type]);

  @override
  String _stringifyValue() {
    return StringDumper(value).dump();
  }
}

class KdlBigDecimal extends KdlValue<BigDecimal> {
  KdlBigDecimal(super.value, [super.type]);
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

class KdlDouble extends KdlValue<double> {
  KdlDouble(super.value, [super.type]);

  @override
  bool operator ==(other) {
    var otherValue = other;
    if (other is KdlValue) otherValue = other.value;

    if (value.isNaN && otherValue is double && otherValue.isNaN) return true;
    return value == other;
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

class KdlInt<I> extends KdlValue<I> {
  KdlInt(super.value, [super.type]);

  @override
  bool operator ==(other) => other is KdlInt && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class KdlBool extends KdlValue<bool> {
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

class KdlNull extends KdlValue<Null> {
  KdlNull([String? type]) : super(null, type);

  @override
  bool operator ==(other) => other is KdlNull;

  @override
  int get hashCode => null.hashCode;

  @override
  String _stringifyValue() {
    return '#null';
  }
}
