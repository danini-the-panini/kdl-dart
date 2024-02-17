import "dart:math";

import "../irl/parser.dart";

class URLTemplate {
  List<URLTemplatePart> parts;

  URLTemplate(this.parts);

  expand(values) {
    var result = parts.map((part) => part.expand(values)).join();
    var parser = IRLReferenceParser(result);
    var uri = parser.parse()[0];
    return Uri.parse(uri);
  }

  @override
  String toString() => parts.map((part) => part.toString()).join();
}

enum URLTemplateParserContext {
  Start,
  Literal,
  Expansion,
}

class URLTemplateParser {
  static final UNRESERVED = RegExp(r"[a-zA-Z0-9\-._~]");
  static final RESERVED = RegExp(r"[:/?#\[\]@!$&'()*+,;=]");

  String string;
  int index = 0;

  URLTemplateParser(this.string);

  URLTemplate parse() {
    List<URLTemplatePart> result = [];
    URLTemplatePart? token = null;
    while ((token = _nextToken()) != null) {
      result.add(token!);
    }
    return URLTemplate(result);
  }

  URLTemplatePart? _nextToken() {
    var buffer = '';
    var context = URLTemplateParserContext.Start;
    late URLTemplatePart expansion;
    while (true) {
      var c = index < string.length ? string[index] : null;
      switch (context) {
        case URLTemplateParserContext.Start:
          switch (c) {
            case '{':
              context = URLTemplateParserContext.Expansion;
              buffer = '';
              var n = index < string.length - 1 ? string[index + 1] : null;
              switch (n) {
                case '+': expansion = ReservedExpansion(); break;
                case '#': expansion = FragmentExpansion(); break;
                case '.': expansion = LabelExpansion(); break;
                case '/': expansion = PathExpansion(); break;
                case ';': expansion = ParameterExpansion(); break;
                case '?': expansion = QueryExpansion(); break;
                case '&': expansion = QueryContinuation(); break;
                default: expansion = StringExpansion(); break;
              }
              index += (expansion.runtimeType == StringExpansion) ? 1 : 2;
              break;
            case null: return null;
            default:
              buffer = c;
              index++;
              context = URLTemplateParserContext.Literal;
              break;
          }
          break;
        case URLTemplateParserContext.Literal:
          switch (c) {
            case '{': case null: return StringLiteral(buffer);
            default:
              buffer += c;
              index++;
              break;
          }
          break;
        case URLTemplateParserContext.Expansion:
          switch (c) {
            case '}':
              index++;
              _parseVariables(buffer, expansion);
              return expansion;
            case null:
              throw 'unterminated expansion';
            default:
              buffer += c;
              index++;
              break;
          }
          break;
      }
    }
  }

  void _parseVariables(String string, URLTemplatePart part) {
    part.variables = string.split(',').map((str) {
      var match = RegExp(r"^(.*)\*$").firstMatch(str);
      if (match != null) {
        return URLTemplateVariable(
          match[1]!,
          explode: true,
          allowReserved: part.allowReserved,
          withName: part.withName,
          keepEmpties: part.keepEmpties,
        );
      }
      match = RegExp(r"^(.*):(\d+)$").firstMatch(str);
      if (match != null) {
        return URLTemplateVariable(
          match[1]!,
          limit: int.parse(match[2]!),
          allowReserved: part.allowReserved,
          withName: part.withName,
          keepEmpties: part.keepEmpties,
        );
      }
      return URLTemplateVariable(
        str,
        allowReserved: part.allowReserved,
        withName: part.withName,
        keepEmpties: part.keepEmpties,
      );
    }).toList();
  }
}

class URLTemplateVariable {
  String name;
  int? limit;
  bool explode;
  bool allowReserved;
  bool withName;
  bool keepEmpties;

  URLTemplateVariable(this.name, {
    this.limit,
    this.explode = false,
    this.allowReserved = false,
    this.withName = false,
    this.keepEmpties = false
  });

  expand(value) {
    if (explode) {
      if (value is List) {
        return value.map((v) => _prefix(_encode(v)));
      }
      if (value is Map) {
        return value.entries.map((e) => _prefix(_encode(e.value), e.key));
      }
      return [_prefix(_encode(value))];
    }
    if (limit != null) {
      return [_prefix(_limit(value))].where((x) => x != null);
    }
    return [_prefix(_flatten(value))].where((x) => x != null);
  }

  @override
  String toString() {
    var result = name;
    if (limit != null) result += ":$limit";
    if (explode) result += "*";
    return result;
  }

  _limit(String? string) {
    if (string == null) return null;

    return _encode(string.substring(0, min(limit!, string.length)));
  }

  _flatten(value) {
    if (value is String) {
      return _encode(value);
    }
    if (value is Map) {
      var list = [];
      value.entries.forEach((entry) {
        list.add(entry.key);
        list.add(entry.value);
      });
      return _flatten(list);
    }
    if (value is List) {
      var result = value.where((x) => x != null).map(_encode);
      return result.isEmpty ? null : result.join(',');
    }
  }
  
  _encode(value) {
    if (value == null) return null;

    String string = value.toString();
    var result = '';
    for (int i = 0; i < string.length; i++) {
      var c = string[i];
      if (URLTemplateParser.UNRESERVED.hasMatch(c) || (allowReserved && URLTemplateParser.RESERVED.hasMatch(c))) {
        result += c;
      } else {
        result += IRLReferenceParser.percentEncode(c);
      }
    }
    return result;
  }

  _prefix(String? string, [String? override]) {
    if (string == null) return null;

    var key = override ?? name;

    if (withName || (override != null)) {
      if (string.isEmpty && !keepEmpties) {
        return _encode(key);
      } else {
        return "${_encode(key)}=$string";
      }
    } else {
      return string;
    }
  }
}

abstract class URLTemplatePart {
  List<URLTemplateVariable> variables;

  URLTemplatePart([this.variables = const []]);

  _expandVariables(values) {
    var list = [];
    variables.forEach((variable) {
      var expanded = variable.expand(values[variable.name]);
      if (expanded != null) list.addAll(expanded);
    });
    return list;
  }

  String get separator => ',';
  String get prefix => '';
  bool get allowReserved => false;
  bool get withName => false;
  bool get keepEmpties => false;

  String expand(values);
}

class StringLiteral extends URLTemplatePart {
  String value;

  StringLiteral(this.value) : super([]);

  @override
  expand(values) => value;

  @override
  String toString() => value;
}

class StringExpansion extends URLTemplatePart {
  StringExpansion([List<URLTemplateVariable> variables = const []]) : super(variables);

  @override
  expand(values) {
    var expanded = _expandVariables(values);
    if (expanded.isEmpty) return '';

    return prefix + expanded.join(separator);
  }

  @override
  String toString() => "{${variables.join(',')}}";
}

class ReservedExpansion extends StringExpansion {
  @override
  bool get allowReserved => true;

  @override
  String toString() => "{+${variables.join(',')}}";
}

class FragmentExpansion extends StringExpansion {
  @override
  String get prefix => '#';

  @override
  bool get allowReserved => true;

  @override
  String toString() => "{#${variables.join(',')}}";
}

class LabelExpansion extends StringExpansion {
  @override
  String get prefix => '.';

  @override
  String get separator => '.';

  @override
  String toString() => "{.${variables.join(',')}}";
}

class PathExpansion extends StringExpansion {
  @override
  String get prefix => '/';

  @override
  String get separator => '/';

  @override
  String toString() => "{/${variables.join(',')}}";
}

class ParameterExpansion extends StringExpansion {
  @override
  String get prefix => ';';

  @override
  String get separator => ';';

  @override
  bool get withName => true;

  @override
  String toString() => "{;${variables.join(',')}}";
}

class QueryExpansion extends StringExpansion {
  @override
  String get prefix => '?';

  @override
  String get separator => '&';

  @override
  bool get withName => true;

  @override
  bool get keepEmpties => true;

  @override
  String toString() => "{?${variables.join(',')}}";
}

class QueryContinuation extends QueryExpansion {
  @override get prefix => '&';

  @override
  String toString() => "{&${variables.join(',')}}";
}
