import "package:kdl/src/string_dumper.dart";
import 'package:big_decimal/big_decimal.dart';

_sameNodes(List<KdlNode> nodes, List<KdlNode> otherNodes) {
  if (nodes.length != otherNodes.length) return false;

  for (var i = 0; i < nodes.length; i++) {
    if (nodes[i] != otherNodes[i]) return false;
  }

  return true;
}

class KdlDocument {
  List<KdlNode> nodes = [];

  KdlDocument(List<KdlNode> initialNodes) {
    this.nodes = initialNodes;
  }

  @override
  bool operator ==(other) => other is KdlDocument && _sameNodes(nodes, other.nodes);

  @override
  int get hashCode => nodes.hashCode;

  @override
  String toString() {
    return nodes.map((e) => e.toString()).join("\n") + "\n";
  }
}

class KdlNode {
  String name = '';
  String? type = null;
  List<KdlNode> children = [];
  List<KdlValue> arguments = [];
  Map<String, KdlValue> properties = {};

  KdlNode(String name, {
    List<KdlNode>? children = null,
    List<KdlValue>? arguments = null,
    Map<String, KdlValue>? properties = null,
    String? type = null
  }) {
    this.name = name;
    this.children = children ?? [];
    this.arguments = arguments ?? [];
    this.properties = properties ?? {};
    this.type = type;
  }

  @override
  bool operator ==(other) => other is KdlNode
    && name == other.name
    && _sameNodes(this.children, other.children)
    && _sameArguments(other.arguments)
    && _sameProperties(other.properties);

  @override
  int get hashCode => [children, arguments, properties].hashCode;

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

    if (result == null) return this.asType(type);

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
      s += " ${properties.entries.map((e) => "${_idToString(e.key)}=${e.value}").join(' ')}";
    }
    if (children.isNotEmpty) {
      var childrenStr = children.map((e) => e._toStringWithIndentation(indentation + 1)).join("\n");
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

    return properties.entries.every((element) => otherProps[element.key] == element.value);
  }

  _idToString(String id) {
    return StringDumper(id).stringifyIdentifier();
  }
}

abstract class KdlValue<T> {
  late T value;
  String? type = null;

  KdlValue(this.value, [this.type]) {
    this.value = value;
    this.type = type;
  }

  static KdlValue from(v, [String? type]) {
    if (v is String) return KdlString(v, type);
    if (v is int) return KdlInt(v, type);
    if (v is BigDecimal) return KdlFloat(v, type);
    if (v is bool) return KdlBool(v, type);
    if (v == null) return KdlNull(type);
    throw "No KDL value for ${v}";
  }

  @override
  String toString() {
    if (type == null) {
      return _stringifyValue();
    } else {
      return "(${StringDumper(type!).stringifyIdentifier()})${_stringifyValue()}";
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
  bool operator ==(other) => other is KdlString && this.value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String _stringifyValue() {
    return StringDumper(value).dump();
  }
}

class KdlFloat extends KdlValue<BigDecimal> {
  KdlFloat(BigDecimal value, [String? type]) : super(value, type);
  KdlFloat.from(num value, [String? type]) : super(BigDecimal.parse(value.toString()), type);

  @override
  bool operator ==(other) => other is KdlFloat && this.value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String _stringifyValue() {
    return value.toString().toUpperCase();
  }
}

class KdlInt<I> extends KdlValue<I> {
  KdlInt(I value, [String? type]) : super(value, type);

  @override
  bool operator ==(other) => other is KdlInt && this.value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class KdlBool extends KdlValue<bool> {
  KdlBool(bool value, [String? type]) : super(value, type);

  @override
  bool operator ==(other) => other is KdlBool && this.value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String _stringifyValue() {
    return value ? 'true' : 'false';
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
    return 'null';
  }
}
