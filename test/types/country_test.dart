import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/country.dart';
import 'package:kdl/src/types/country/iso3166_countries.dart';

void main() {
  var southAfrica = Country(alpha3: 'ZAF', alpha2: 'ZA', numericCode: 710, name: 'South Africa');

  test('country3', () {
    expect(KdlCountry3.convert(KdlString('ZAF'))!.value, equals(southAfrica));

    expect(() => KdlCountry3.convert(KdlString('ZZZ')), throwsA(anything));
  });

  test('country2', () {
    expect(KdlCountry2.convert(KdlString('ZA'))!.value, equals(southAfrica));

    expect(() => KdlCountry2.convert(KdlString('ZZ')), throwsA(anything));
  });

  test('country subdivision', () {
    var value = KdlCountrySubdivision.convert(KdlString('ZA-GP'))!;
    expect(value.value, equals('ZA-GP'));
    expect(value.name, equals('Gauteng'));
    expect(value.country, equals(southAfrica));

    expect(() => KdlCountrySubdivision.convert(KdlString('ZA-ZZ')), throwsA(anything));
    expect(() => KdlCountrySubdivision.convert(KdlString('ZZ-GP')), throwsA(anything));
  });
}
