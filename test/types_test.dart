import 'package:test/test.dart';

import 'package:kdl/kdl.dart';
import 'package:kdl/src/parser.dart';

class Foo extends KdlValue<String> {
  Foo(super.value, [super.type]);
}

class Bar extends KdlNode {
  Bar(KdlNode node, [String? type])
      : super(
          node.name,
          arguments: node.arguments,
          properties: node.properties,
          children: node.children,
          type: type,
        );
}

void main() {
  late KdlParser parser;

  setUp(() {
    parser = KdlParser();
  });

  test('built in types', () {
    var doc = parser.parse("""

node (date-time)"2021-01-01T12:12:12" \\
     (date)"2021-01-01" \\
     (time)"22:23:12" \\
     (duration)"P3Y6M4DT12H30M5S" \\
     (decimal)"10000000000000" \\
     (currency)"ZAR" \\
     (country-2)"ZA" \\
     (country-3)"ZAF" \\
     (country-subdivision)"ZA-GP" \\
     (email)"simple@example.com" \\
     (idn-email)"🌈@xn--9ckb.com" \\
     (hostname)"www.example.com" \\
     (idn-hostname)"xn--bcher-kva.example" \\
     (ipv4)"127.0.0.1" \\
     (ipv6)"3ffe:505:2::1" \\
     (url)"https://kdl.dev" \\
     (url-reference)"/foo/bar" \\
     (irl)"https://kdl.dev/🦄" \\
     (irl-reference)"/🌈/🦄" \\
     (url-template)"https://kdl.dev/{foo}" \\
     (uuid)"f81d4fae-7dec-11d0-a765-00a0c91e6bf6" \\
     (regex)"asdf" \\
     (base64)"U2VuZCByZWluZm9yY2VtZW50cw=="
"""
        .trim());

    var i = 0;
    expect(doc.nodes[0].arguments[i++], isA<KdlDateTime>());
    expect(doc.nodes[0].arguments[i++], isA<KdlDate>());
    expect(doc.nodes[0].arguments[i++], isA<KdlTime>());
    expect(doc.nodes[0].arguments[i++], isA<KdlDuration>());
    expect(doc.nodes[0].arguments[i++], isA<KdlDecimal>());
    expect(doc.nodes[0].arguments[i++], isA<KdlCurrency>());
    expect(doc.nodes[0].arguments[i++], isA<KdlCountry2>());
    expect(doc.nodes[0].arguments[i++], isA<KdlCountry3>());
    expect(doc.nodes[0].arguments[i++], isA<KdlCountrySubdivision>());
    expect(doc.nodes[0].arguments[i++], isA<KdlEmail>());
    expect(doc.nodes[0].arguments[i++], isA<KdlIdnEmail>());
    expect(doc.nodes[0].arguments[i++], isA<KdlHostname>());
    expect(doc.nodes[0].arguments[i++], isA<KdlIdnHostname>());
    expect(doc.nodes[0].arguments[i++], isA<KdlIPV4>());
    expect(doc.nodes[0].arguments[i++], isA<KdlIPV6>());
    expect(doc.nodes[0].arguments[i++], isA<KdlUrl>());
    expect(doc.nodes[0].arguments[i++], isA<KdlUrlReference>());
    expect(doc.nodes[0].arguments[i++], isA<KdlIRL>());
    expect(doc.nodes[0].arguments[i++], isA<KdlIrlReference>());
    expect(doc.nodes[0].arguments[i++], isA<KdlUrlTemplate>());
    expect(doc.nodes[0].arguments[i++], isA<KdlUuid>());
    expect(doc.nodes[0].arguments[i++], isA<KdlRegex>());
    expect(doc.nodes[0].arguments[i++], isA<KdlBase64>());
  });

  test('custom types', () {
    var customValues = {
      'foo': (KdlValue value, String type) {
        return Foo(value.value, type);
      }
    };
    var customNodes = {
      'bar': (KdlNode node, type) {
        return Bar(node, type);
      },
    };
    var doc = KdlDocument.parse(
        """
(bar)barnode (foo)"foovalue"
(foo)foonode (bar)"barvalue"
"""
            .trim(),
        valueTypes: customValues,
        nodeTypes: customNodes);

    expect(doc, isNotNull);
    expect(doc.nodes[0], isA<Bar>());
    expect(doc.nodes[0].arguments[0], isA<Foo>());
    expect(doc.nodes[1], isA<KdlNode>());
    expect(doc.nodes[1].arguments[0], isA<KdlValue>());
  });

  test('parse false', () {
    var doc = KdlDocument.parse(
        """
node (date-time)"2021-01-01T12:12:12"
    """
            .trim(),
        parseTypes: false);

    expect(doc, isNotNull);
    expect(doc.nodes[0].arguments[0], isA<KdlString>());
  });
}
