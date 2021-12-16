import "../document.dart";
import "./country/iso3166_countries.dart";
import "./country/iso3166_subdivisions.dart";

class KdlCountry extends KdlValue<Country> {
  KdlCountry(Country value, [String? type]) : super(value, type);
}

class KdlCountry2 extends KdlCountry {
  KdlCountry2(Country value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'country2']) {
    if (!(value is KdlString)) return null;

    var country = Country.COUNTRIES2[value.value];
    if (country == null) throw "invalid country2: ${value.value}";

    return KdlCountry2(country, type);
  }
}

class KdlCountry3 extends KdlCountry {
  KdlCountry3(Country value, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'country3']) {
    if (!(value is KdlString)) return null;

    var country = Country.COUNTRIES3[value.value];
    if (country == null) throw "invalid country3: ${value.value}";

    return KdlCountry3(country, type);
  }
}

class KdlCountrySubdivision extends KdlValue<String> {
  String name;
  Country country;

  KdlCountrySubdivision(String value, this.name, this.country, [String? type]) : super(value, type);

  static call(KdlValue value, [String type = 'country-subdivision']) {
    if (!(value is KdlString)) return null;

    var parts = value.value.split('-');
    if (parts.length != 2) throw "invalid country subdivision: ${value.value}";
    var country2 = parts[0];
    var subdivisionCode = parts[1];

    var country = Country.COUNTRIES2[country2];
    if (country == null) throw "invalid country2: ${country2}";

    var subdivisions = COUNTRY_SUBDIVISIONS[country2];
    if (subdivisions == null) throw "invalid country: ${country2}";

    var subdivision = subdivisions[value.value];
    if (subdivision == null) throw "invalid subdivision: ${subdivisionCode}";

    return KdlCountrySubdivision(value.value, subdivision, country, type);
  }
}
