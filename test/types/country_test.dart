import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/country.dart';
import 'package:kdl/src/types/country/iso3166_countries.dart';

void main() {
  var southAfrica = Country(alpha3: 'ZAF', alpha2: 'ZA', numericCode: 710, name: 'South Africa');

  test('country3', () {
    expect(KdlCountry3.call(KdlString('ZAF')).value, equals(southAfrica));

    expect(() => KdlCountry3.call(KdlString('ZZZ')), throwsA(anything));
  });

  test('country2', () {
    expect(KdlCountry2.call(KdlString('ZA')).value, equals(southAfrica));

    expect(() => KdlCountry2.call(KdlString('ZZ')), throwsA(anything));
  });

  test('country subdivision', () {
    var value = KdlCountrySubdivision.call(KdlString('ZA-GP'));
    expect(value.value, equals('ZA-GP'));
    expect(value.name, equals('Gauteng'));
    expect(value.country, equals(southAfrica));

    expect(() => KdlCountrySubdivision.call(KdlString('ZA-ZZ')), throwsA(anything));
    expect(() => KdlCountrySubdivision.call(KdlString('ZZ-GP')), throwsA(anything));
  });
}
