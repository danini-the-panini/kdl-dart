import 'dart:collection';

import "package:kdl/src/string_dumper.dart";
import 'package:big_decimal/big_decimal.dart';

_sameNodes(List<KdlNode> nodes, List<KdlNode> otherNodes) {
  if (nodes.length != otherNodes.length) return false;

  for (var i = 0; i < nodes.length; i++) {
    if (nodes[i] != otherNodes[i]) return false;
  }

  return true;
}

class KdlDocument with IterableMixin<KdlNode> {
  List<KdlNode> nodes = [];

  KdlDocument(List<KdlNode> initialNodes) {
    this.nodes = initialNodes;
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
    return nodes.map((e) => e.toString()).join("\n") + "\n";
  }
}

class KdlNode with IterableMixin<KdlNode> {
  String name = '';
  String? type = null;
  List<KdlNode> children = [];
  List<KdlValue> arguments = [];
  Map<String, KdlValue> properties = {};

  KdlNode(String name,
      {List<KdlNode>? children = null,
      List<KdlValue>? arguments = null,
      Map<String, KdlValue>? properties = null,
      String? type = null}) {
    this.name = name;
    this.children = children ?? [];
    this.arguments = arguments ?? [];
    this.properties = properties ?? {};
    this.type = type;
  }

  bool get hasChildren {
    return this.children.isNotEmpty;
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

    if (!(result is KdlNode)) {
      throw "expected parser to return an instance of KdlNode, got ${result.runtimeType}";
    }

    return result;
  }

  String _toStringWithIndentation(int indentation) {
    String indent = "    " * indentation;
    String typeStr = type != null ? "(${_idToString(type!)})" : "";
    String s = "${indent}${typeStr}${_idToString(name)}";
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
      s += " {\n${childrenStr}\n${indent}}";
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
  String? type = null;

  KdlValue(this.value, [this.type]);

  static KdlValue from(v, [String? type]) {
    if (v is String) return KdlString(v, type);
    if (v is int) return KdlInt(v, type);
    if (v is double) return KdlDouble(v, type);
    if (v is BigDecimal) return KdlBigDecimal(v, type);
    if (v is bool) return KdlBool(v, type);
    if (v == null) return KdlNull(type);
    throw "No KDL value for ${v}";
  }

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

    if (!(result is KdlValue)) {
      throw "expected parser to return an instance of KdlValue, got ${result.runtimeType}";
    }

    return result;
  }

  String _stringifyValue() {
    return value.toString();
  }
}

class KdlString extends KdlValue<String> {
  KdlString(String value, [String? type]) : super(value, type);

  @override
  int get hashCode => value.hashCode;

  @override
  String _stringifyValue() {
    return StringDumper(value).dump();
  }
}

class KdlBigDecimal extends KdlValue<BigDecimal> {
  KdlBigDecimal(BigDecimal value, [String? type]) : super(value, type);
  KdlBigDecimal.from(num value, [String? type])
      : super(BigDecimal.parse(value.toString()), type);

  @override
  bool operator ==(other) {
    if (other is KdlBigDecimal) return value == other.value;
    if (other is KdlDouble) return value == other.value;
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
  KdlDouble(double value, [String? type]) : super(value, type);

  @override
  bool operator ==(other) {
    if (other is KdlDouble) return this == other.value;
    if (other is KdlBigDecimal) return value == other.value;

    if (value.isNaN && other is double && other.isNaN) return true;
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
  KdlInt(I value, [String? type]) : super(value, type);

  @override
  bool operator ==(other) => other is KdlInt && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class KdlBool extends KdlValue<bool> {
  KdlBool(bool value, [String? type]) : super(value, type);

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
