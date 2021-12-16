import "dart:io";
import "../document.dart";

class KdlIP extends KdlValue<InternetAddress> {
  KdlIP(InternetAddress value, [String? type]) : super(value, type);
}

class KdlIPV4 extends KdlIP {
  KdlIPV4(InternetAddress value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'ipv4']) {
    if (!(value is KdlString)) return null;

    var addr = InternetAddress(value.value);
    if (addr.type != InternetAddressType.IPv4) {
      throw "invalid ipv4 address: ${value.value}";
    }

    return KdlIPV4(addr, type);
  }
}

class KdlIPV6 extends KdlIP {
  KdlIPV6(InternetAddress value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'ipv6']) {
    if (!(value is KdlString)) return null;

    var addr = InternetAddress(value.value);
    if (addr.type != InternetAddressType.IPv6) {
      throw "invalid ipv6 address: ${value.value}";
    }

    return KdlIPV6(addr, type);
  }
}
