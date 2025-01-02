import "../document.dart";
import "./country/iso3166_countries.dart";
import "./country/iso3166_subdivisions.dart";

/// Base-class for ISO 3166-1 country codes
class KdlCountry extends KdlValue<Country> {
  /// Construct a new `KdlCountry`
  KdlCountry(super.value, [super.type]);
}

/// ISO 3166-1 alpha-2 country code.
class KdlCountry2 extends KdlCountry {
  /// Construct a new `KdlCountry2`
  KdlCountry2(super.value, [super.type]);

  /// Convert a `KdlString` into `KdlCountry2`
  static KdlCountry2? convert(KdlValue value, [String type = 'country2']) {
    if (value is! KdlString) return null;

    var country = Country.countries2[value.value];
    if (country == null) throw "invalid country2: ${value.value}";

    return KdlCountry2(country, type);
  }
}

/// ISO 3166-1 alpha-3 country code.
class KdlCountry3 extends KdlCountry {
  /// Construct a new `KdlCountry3`
  KdlCountry3(super.value, [super.type]);

  /// Convert a `KdlString` into `KdlCountry3`
  static KdlCountry3? convert(KdlValue value, [String type = 'country3']) {
    if (value is! KdlString) return null;

    var country = Country.countries3[value.value];
    if (country == null) throw "invalid country3: ${value.value}";

    return KdlCountry3(country, type);
  }
}

/// ISO 3166-2 country subdivision code.
class KdlCountrySubdivision extends KdlValue<String> {
  /// Name of the subdivision
  String name;

  /// The country in which the subdivision resides
  Country country;

  /// Construct a new KDL Country Subdivision
  KdlCountrySubdivision(super.value, this.name, this.country, [super.type]);

  /// Convert a `KdlString` into a `KdlCountrySubdivision`
  static KdlCountrySubdivision? convert(KdlValue value,
      [String type = 'country-subdivision']) {
    if (value is! KdlString) return null;

    var parts = value.value.split('-');
    if (parts.length != 2) throw "invalid country subdivision: ${value.value}";
    var country2 = parts[0];
    var subdivisionCode = parts[1];

    var country = Country.countries2[country2];
    if (country == null) throw "invalid country2: $country2";

    var subdivisions = countrySubdivisions[country2];
    if (subdivisions == null) throw "invalid country: $country2";

    var subdivision = subdivisions[value.value];
    if (subdivision == null) throw "invalid subdivision: $subdivisionCode";

    return KdlCountrySubdivision(value.value, subdivision, country, type);
  }
}
