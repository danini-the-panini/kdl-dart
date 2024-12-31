import "../document.dart";
import "./email/parser.dart";

class KdlEmail extends KdlValue<String> {
  String local;
  String domain;

  KdlEmail(super.value, this.local, this.domain, [super.type]);

  static call(KdlValue value, [String type = 'email']) {
    if (value is! KdlString) return null;

    var parts = EmailParser(value.value).parse();

    return KdlEmail(value.value, parts[0], parts[1], type);
  }
}

class KdlIDNEmail extends KdlEmail {
  String unicodeValue;
  String unicodeDomain;
  KdlIDNEmail(super.value, this.unicodeValue, super.local, super.domain,
      this.unicodeDomain,
      [super.type]);

  static call(KdlValue value, [String type = 'idn-email']) {
    if (value is! KdlString) return null;

    var parts = EmailParser(value.value, idn: true).parse();

    return KdlIDNEmail("${parts[0]}@${parts[1]}", "${parts[0]}@${parts[2]}",
        parts[0], parts[1], parts[2], type);
  }
}
