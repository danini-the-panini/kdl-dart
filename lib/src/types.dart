import "./types/date_time.dart";
import "./types/duration.dart";
import "./types/decimal.dart";
import "./types/currency.dart";
import "./types/country.dart";
import "./types/email.dart";
import "./types/hostname.dart";
import "./types/ip.dart";
import "./types/url.dart";
import "./types/irl.dart";
import "./types/url_template.dart";
import "./types/uuid.dart";
import "./types/regex.dart";
import "./types/base64.dart";

class KdlTypes {
  static Map<String, Function> MAPPING = const {
    'date-time': KdlDateTime.call,
    'time': KdlTime.call,
    'date': KdlDate.call,
    'duration': KdlDuration.call,
    'decimal': KdlDecimal.call,
    'currency': KdlCurrency.call,
    'country-2': KdlCountry2.call,
    'country-3': KdlCountry3.call,
    'country-subdivision': KdlCountrySubdivision.call,
    'email': KdlEmail.call,
    'idn-email': KdlIDNEmail.call,
    'hostname': KdlHostname.call,
    'idn-hostname': KdlIDNHostname.call,
    'ipv4': KdlIPV4.call,
    'ipv6': KdlIPV6.call,
    'url': KdlURL.call,
    'url-reference': KdlURLReference.call,
    'irl': KdlIRL.call,
    'irl-reference': KdlIRLReference.call,
    'url-template': KdlURLTemplate.call,
    'uuid': KdlUUID.call,
    'regex': KdlRegex.call,
    'base64': KdlBase64.call,
  };
}
