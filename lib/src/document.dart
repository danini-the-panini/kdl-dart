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
    return nodes.map((e) => e.toString()).join("\n");
  }
}

class KdlNode {
  String name = '';
  List<KdlNode> children = [];
  List<KdlValue> arguments = [];
  Map<String, KdlValue> properties = {};

  KdlNode(String name, {
    List<KdlNode>? children = null,
    List<KdlValue>? arguments = null,
    Map<String, KdlValue>? properties = null
  }) {
    this.name = name;
    this.children = children ?? [];
    this.arguments = arguments ?? [];
    this.properties = properties ?? {};
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

  String _toStringWithIndentation(int indentation) {
    String s = "${"  " * indentation}${name}";
    if (arguments.isNotEmpty) {
      s += " ${arguments.map((a) => a.toString()).join(' ')}";
    }
    if (properties.isNotEmpty) {
      s += " ${properties.entries.map((e) => "${e.key}=${e.value}").join(' ')}";
    }
    if (children.isNotEmpty) {
      s += " {\n${children.map((e) => e._toStringWithIndentation(indentation + 1)).join("\n")}\n${"  " * indentation}}";
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
}

abstract class KdlValue {
  static KdlValue from(v) {
    if (v is String) return KdlString(v);
    if (v is int) return KdlInt(v);
    if (v is double) return KdlFloat(v);
    if (v is bool) return KdlBool(v);
    if (v == null) return KdlNull();
    throw "No KDL value for ${v}";
  }
}

class KdlString extends KdlValue {
  String value = "";

  KdlString(value) {
    this.value = value;
  }

  @override
  bool operator ==(other) => other is KdlString && this.value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return "\"${value}\""; // TODO: escape string
  }
}

class KdlFloat extends KdlValue {
  double value = 0.0;

  KdlFloat(value) {
    this.value = value;
  }

  @override
  bool operator ==(other) => other is KdlFloat && this.value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return value.toString();
  }
}

class KdlInt extends KdlValue {
  int value = 0;

  KdlInt(value) {
    this.value = value;
  }

  @override
  bool operator ==(other) => other is KdlInt && this.value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return value.toString();
  }
}

class KdlBool extends KdlValue {
  bool value = false;

  KdlBool(value) {
    this.value = value;
  }

  @override
  bool operator ==(other) => other is KdlBool && this.value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return value ? 'true' : 'false';
  }
}

class KdlNull extends KdlValue {
  @override
  bool operator ==(other) => other is KdlNull;

  @override
  int get hashCode => null.hashCode;

  @override
  String toString() {
    return 'null';
  }
}
