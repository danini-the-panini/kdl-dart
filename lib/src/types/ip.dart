import "package:kdl/src/document.dart";
import "package:kdl/src/exception.dart";

class KdlIP extends KdlValue<String> {
  KdlIP(String value, [String? type]) : super(value, type);
}

class KdlIPV4 extends KdlIP {
  static final _DECBYTE = r"""
    0
    |1(?:[0-9][0-9]?)?
    |2(?:[0-4][0-9]?|5[0-5]?|[6-9])?
    |[3-9][0-9]?
  """
      .trim()
      .split('\n')
      .map((v) => v.trim())
      .join();
  static final PATTERN =
      RegExp("^($_DECBYTE)\.($_DECBYTE)\.($_DECBYTE)\.($_DECBYTE)\$");

  KdlIPV4(String value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'ipv4']) {
    if (!(value is KdlString)) return null;
    var addr = value.value;

    if (!PATTERN.hasMatch(addr)) {
      throw KdlException("invalid ipv4 address: ${addr}");
    }

    return KdlIPV4(addr, type);
  }
}

class KdlIPV6 extends KdlIP {
  // IPv6 address format a:b:c:d:e:f:g:h
  static final _8HEX = r"""
    (?:[0-9A-Fa-f]{1,4}:){7}
      [0-9A-Fa-f]{1,4}
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // Compressed IPv6 address format a::b
  static final _COMPRESSED_HEX = r"""
    ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::
    ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // IPv4 mapped IPv6 address format a:b:c:d:e:f:w.x.y.z
  static final _6HEX_4DEC = r"""
    ((?:[0-9A-Fa-f]{1,4}:){6,6})
    (\d+)\.(\d+)\.(\d+)\.(\d+)
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // Compressed IPv4 mapped IPv6 address format a::b:w.x.y.z
  static final _COMPRESSED_HEX_4DEC = r"""
    ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::
    ((?:[0-9A-Fa-f]{1,4}:)*)
    (\d+)\.(\d+)\.(\d+)\.(\d+)
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // IPv6 link local address format fe80:b:c:d:e:f:g:h%em1
  static final _8HEX_LINK_LOCAL = r"""
    [Ff][Ee]80
    (?::[0-9A-Fa-f]{1,4}){7}
    %[-0-9A-Za-z._~]+
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // Compressed IPv6 link local address format fe80::b%em1
  static final _COMPRESSED_HEX_LINK_LOCAL = r"""
    [Ff][Ee]80:
    (?:
      ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::
      ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)
      |
      :((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)
    )?
    :[0-9A-Fa-f]{1,4}%[-0-9A-Za-z._~]+
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // A composite IPv6 address Regexp.
  static final PATTERN = RegExp("^${[
    _8HEX,
    _COMPRESSED_HEX,
    _6HEX_4DEC,
    _COMPRESSED_HEX_4DEC,
    _8HEX_LINK_LOCAL,
    _COMPRESSED_HEX_LINK_LOCAL
  ].map((v) => "(?:$v)").join('|')}\$");

  KdlIPV6(String value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'ipv6']) {
    if (!(value is KdlString)) return null;
    var addr = value.value;

    if (!PATTERN.hasMatch(addr)) {
      throw KdlException("invalid ipv6 address: ${addr}");
    }

    return KdlIPV6(addr, type);
  }
}
