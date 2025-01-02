import "dart:math";

import "../irl/parser.dart";

/// RFC6570 URI Template.
class UrlTemplate {
  final List<_UrlTemplatePart> _parts;

  /// Construct a new URL template with the given parts
  UrlTemplate(this._parts);

  /// Expand the template into a Uri with the given values
  Uri expand(values) {
    var result = _parts.map((p) => p._expand(values)).join();
    var parser = IrlParser(result);
    return Uri.parse(parser.parse().asciiValue);
  }

  @override
  String toString() => _parts.map((p) => p.toString()).join();
}

enum _UrlTemplateParserContext {
  start,
  literal,
  expansion,
}

/// Parses a string into a URLTemplate
class UrlTemplateParser {
  static final _unreserved = RegExp(r"[a-zA-Z0-9\-._~]");
  static final _reserved = RegExp(r"[:/?#\[\]@!$&'()*+,;=]");

  final String _string;
  int _index = 0;

  /// Construct a new URL template parser for parsing the given string
  UrlTemplateParser(this._string);

  /// Parse the string into a URL template
  UrlTemplate parse() {
    List<_UrlTemplatePart> result = [];
    _UrlTemplatePart? token;
    while ((token = _nextToken()) != null) {
      result.add(token!);
    }
    return UrlTemplate(result);
  }

  _UrlTemplatePart? _nextToken() {
    var buffer = '';
    var context = _UrlTemplateParserContext.start;
    late _UrlTemplatePart expansion;
    while (true) {
      var c = _index < _string.length ? _string[_index] : null;
      switch (context) {
        case _UrlTemplateParserContext.start:
          switch (c) {
            case '{':
              context = _UrlTemplateParserContext.expansion;
              buffer = '';
              var n = _index < _string.length - 1 ? _string[_index + 1] : null;
              switch (n) {
                case '+':
                  expansion = _ReservedExpansion();
                  break;
                case '#':
                  expansion = _FragmentExpansion();
                  break;
                case '.':
                  expansion = _LabelExpansion();
                  break;
                case '/':
                  expansion = _PathExpansion();
                  break;
                case ';':
                  expansion = _ParameterExpansion();
                  break;
                case '?':
                  expansion = _QueryExpansion();
                  break;
                case '&':
                  expansion = _QueryContinuation();
                  break;
                default:
                  expansion = _StringExpansion();
                  break;
              }
              _index += (expansion.runtimeType == _StringExpansion) ? 1 : 2;
              break;
            case null:
              return null;
            default:
              buffer = c;
              _index++;
              context = _UrlTemplateParserContext.literal;
              break;
          }
          break;
        case _UrlTemplateParserContext.literal:
          switch (c) {
            case '{':
            case null:
              return _StringLiteral(buffer);
            default:
              buffer += c;
              _index++;
              break;
          }
          break;
        case _UrlTemplateParserContext.expansion:
          switch (c) {
            case '}':
              _index++;
              _parseVariables(buffer, expansion);
              return expansion;
            case null:
              throw 'unterminated expansion';
            default:
              buffer += c;
              _index++;
              break;
          }
          break;
      }
    }
  }

  void _parseVariables(String string, _UrlTemplatePart part) {
    part._variables = string.split(',').map((str) {
      var match = RegExp(r"^(.*)\*$").firstMatch(str);
      if (match != null) {
        return _UrlTemplateVariable(
          match[1]!,
          explode: true,
          allowReserved: part._allowReserved,
          withName: part._withName,
          keepEmpties: part._keepEmpties,
        );
      }
      match = RegExp(r"^(.*):(\d+)$").firstMatch(str);
      if (match != null) {
        return _UrlTemplateVariable(
          match[1]!,
          limit: int.parse(match[2]!),
          allowReserved: part._allowReserved,
          withName: part._withName,
          keepEmpties: part._keepEmpties,
        );
      }
      return _UrlTemplateVariable(
        str,
        allowReserved: part._allowReserved,
        withName: part._withName,
        keepEmpties: part._keepEmpties,
      );
    }).toList();
  }
}

class _UrlTemplateVariable {
  String name;
  int? limit;
  bool explode;
  bool allowReserved;
  bool withName;
  bool keepEmpties;

  _UrlTemplateVariable(this.name,
      {this.limit,
      this.explode = false,
      this.allowReserved = false,
      this.withName = false,
      this.keepEmpties = false});

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
      for (var entry in value.entries) {
        list.add(entry.key);
        list.add(entry.value);
      }
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
      if (UrlTemplateParser._unreserved.hasMatch(c) ||
          (allowReserved && UrlTemplateParser._reserved.hasMatch(c))) {
        result += c;
      } else {
        result += IrlParser.percentEncode(c);
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

abstract class _UrlTemplatePart {
  List<_UrlTemplateVariable> _variables;

  _UrlTemplatePart([this._variables = const []]);

  _expandVariables(Map<String, dynamic> values) {
    var list = [];
    for (var variable in _variables) {
      var expanded = variable.expand(values[variable.name]);
      if (expanded != null) list.addAll(expanded);
    }
    return list;
  }

  String get _separator => ',';
  String get _prefix => '';
  bool get _allowReserved => false;
  bool get _withName => false;
  bool get _keepEmpties => false;

  String _expand(values);
}

class _StringLiteral extends _UrlTemplatePart {
  String value;

  _StringLiteral(this.value) : super([]);

  @override
  _expand(values) => value;

  @override
  String toString() => value;
}

class _StringExpansion extends _UrlTemplatePart {
  @override
  _expand(values) {
    var expanded = _expandVariables(values);
    if (expanded.isEmpty) return '';

    return _prefix + expanded.join(_separator);
  }

  @override
  String toString() => "{${_variables.join(',')}}";
}

class _ReservedExpansion extends _StringExpansion {
  @override
  bool get _allowReserved => true;

  @override
  String toString() => "{+${_variables.join(',')}}";
}

class _FragmentExpansion extends _StringExpansion {
  @override
  String get _prefix => '#';

  @override
  bool get _allowReserved => true;

  @override
  String toString() => "{#${_variables.join(',')}}";
}

class _LabelExpansion extends _StringExpansion {
  @override
  String get _prefix => '.';

  @override
  String get _separator => '.';

  @override
  String toString() => "{.${_variables.join(',')}}";
}

class _PathExpansion extends _StringExpansion {
  @override
  String get _prefix => '/';

  @override
  String get _separator => '/';

  @override
  String toString() => "{/${_variables.join(',')}}";
}

class _ParameterExpansion extends _StringExpansion {
  @override
  String get _prefix => ';';

  @override
  String get _separator => ';';

  @override
  bool get _withName => true;

  @override
  String toString() => "{;${_variables.join(',')}}";
}

class _QueryExpansion extends _StringExpansion {
  @override
  String get _prefix => '?';

  @override
  String get _separator => '&';

  @override
  bool get _withName => true;

  @override
  bool get _keepEmpties => true;

  @override
  String toString() => "{?${_variables.join(',')}}";
}

class _QueryContinuation extends _QueryExpansion {
  @override
  get _prefix => '&';

  @override
  String toString() => "{&${_variables.join(',')}}";
}
