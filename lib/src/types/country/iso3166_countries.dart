/// Represents a country
class Country {
  /// Alpha-3 country code
  String alpha3;

  /// Alpha-2 country code
  String alpha2;

  /// Numeric country code
  int numericCode;

  /// Name of the country
  String name;

  /// Construct a new instance of `Country`
  Country(
      {this.alpha3 = '',
      this.alpha2 = '',
      this.numericCode = 0,
      this.name = ''});

  @override
  bool operator ==(other) =>
      other is Country &&
      other.alpha3 == alpha3 &&
      other.alpha2 == alpha2 &&
      other.numericCode == numericCode &&
      other.name == name;

  @override
  int get hashCode => [alpha2, alpha2, numericCode, name].hashCode;

  @override
  String toString() =>
      "alpha3:$alpha3 alpha2:$alpha2 numericCode:$numericCode name:$name";

  /// Mapping of all countries by alpha-3 code
  static Map<String, Country> countries3 = {
    'AFG': Country(
        alpha3: 'AFG', alpha2: 'AF', numericCode: 4, name: 'Afghanistan'),
    'ALA': Country(
        alpha3: 'ALA', alpha2: 'AX', numericCode: 248, name: 'Åland Islands'),
    'ALB':
        Country(alpha3: 'ALB', alpha2: 'AL', numericCode: 8, name: 'Albania'),
    'DZA':
        Country(alpha3: 'DZA', alpha2: 'DZ', numericCode: 12, name: 'Algeria'),
    'ASM': Country(
        alpha3: 'ASM', alpha2: 'AS', numericCode: 16, name: 'American Samoa'),
    'AND':
        Country(alpha3: 'AND', alpha2: 'AD', numericCode: 20, name: 'Andorra'),
    'AGO':
        Country(alpha3: 'AGO', alpha2: 'AO', numericCode: 24, name: 'Angola'),
    'AIA': Country(
        alpha3: 'AIA', alpha2: 'AI', numericCode: 660, name: 'Anguilla'),
    'ATA': Country(
        alpha3: 'ATA', alpha2: 'AQ', numericCode: 10, name: 'Antarctica'),
    'ATG': Country(
        alpha3: 'ATG',
        alpha2: 'AG',
        numericCode: 28,
        name: 'Antigua and Barbuda'),
    'ARG': Country(
        alpha3: 'ARG', alpha2: 'AR', numericCode: 32, name: 'Argentina'),
    'ARM':
        Country(alpha3: 'ARM', alpha2: 'AM', numericCode: 51, name: 'Armenia'),
    'ABW':
        Country(alpha3: 'ABW', alpha2: 'AW', numericCode: 533, name: 'Aruba'),
    'AUS': Country(
        alpha3: 'AUS', alpha2: 'AU', numericCode: 36, name: 'Australia'),
    'AUT':
        Country(alpha3: 'AUT', alpha2: 'AT', numericCode: 40, name: 'Austria'),
    'AZE': Country(
        alpha3: 'AZE', alpha2: 'AZ', numericCode: 31, name: 'Azerbaijan'),
    'BHS':
        Country(alpha3: 'BHS', alpha2: 'BS', numericCode: 44, name: 'Bahamas'),
    'BHR':
        Country(alpha3: 'BHR', alpha2: 'BH', numericCode: 48, name: 'Bahrain'),
    'BGD': Country(
        alpha3: 'BGD', alpha2: 'BD', numericCode: 50, name: 'Bangladesh'),
    'BRB':
        Country(alpha3: 'BRB', alpha2: 'BB', numericCode: 52, name: 'Barbados'),
    'BLR':
        Country(alpha3: 'BLR', alpha2: 'BY', numericCode: 112, name: 'Belarus'),
    'BEL':
        Country(alpha3: 'BEL', alpha2: 'BE', numericCode: 56, name: 'Belgium'),
    'BLZ':
        Country(alpha3: 'BLZ', alpha2: 'BZ', numericCode: 84, name: 'Belize'),
    'BEN':
        Country(alpha3: 'BEN', alpha2: 'BJ', numericCode: 204, name: 'Benin'),
    'BMU':
        Country(alpha3: 'BMU', alpha2: 'BM', numericCode: 60, name: 'Bermuda'),
    'BTN':
        Country(alpha3: 'BTN', alpha2: 'BT', numericCode: 64, name: 'Bhutan'),
    'BOL': Country(
        alpha3: 'BOL',
        alpha2: 'BO',
        numericCode: 68,
        name: 'Bolivia (Plurinational State of)'),
    'BES': Country(
        alpha3: 'BES',
        alpha2: 'BQ',
        numericCode: 535,
        name: 'Bonaire, Sint Eustatius and Saba[d]'),
    'BIH': Country(
        alpha3: 'BIH',
        alpha2: 'BA',
        numericCode: 70,
        name: 'Bosnia and Herzegovina'),
    'BWA':
        Country(alpha3: 'BWA', alpha2: 'BW', numericCode: 72, name: 'Botswana'),
    'BVT': Country(
        alpha3: 'BVT', alpha2: 'BV', numericCode: 74, name: 'Bouvet Island'),
    'BRA':
        Country(alpha3: 'BRA', alpha2: 'BR', numericCode: 76, name: 'Brazil'),
    'IOT': Country(
        alpha3: 'IOT',
        alpha2: 'IO',
        numericCode: 86,
        name: 'British Indian Ocean Territory'),
    'BRN': Country(
        alpha3: 'BRN',
        alpha2: 'BN',
        numericCode: 96,
        name: 'Brunei Darussalam'),
    'BGR': Country(
        alpha3: 'BGR', alpha2: 'BG', numericCode: 100, name: 'Bulgaria'),
    'BFA': Country(
        alpha3: 'BFA', alpha2: 'BF', numericCode: 854, name: 'Burkina Faso'),
    'BDI':
        Country(alpha3: 'BDI', alpha2: 'BI', numericCode: 108, name: 'Burundi'),
    'CPV': Country(
        alpha3: 'CPV', alpha2: 'CV', numericCode: 132, name: 'Cabo Verde'),
    'KHM': Country(
        alpha3: 'KHM', alpha2: 'KH', numericCode: 116, name: 'Cambodia'),
    'CMR': Country(
        alpha3: 'CMR', alpha2: 'CM', numericCode: 120, name: 'Cameroon'),
    'CAN':
        Country(alpha3: 'CAN', alpha2: 'CA', numericCode: 124, name: 'Canada'),
    'CYM': Country(
        alpha3: 'CYM', alpha2: 'KY', numericCode: 136, name: 'Cayman Islands'),
    'CAF': Country(
        alpha3: 'CAF',
        alpha2: 'CF',
        numericCode: 140,
        name: 'Central African Republic'),
    'TCD': Country(alpha3: 'TCD', alpha2: 'TD', numericCode: 148, name: 'Chad'),
    'CHL':
        Country(alpha3: 'CHL', alpha2: 'CL', numericCode: 152, name: 'Chile'),
    'CHN':
        Country(alpha3: 'CHN', alpha2: 'CN', numericCode: 156, name: 'China'),
    'CXR': Country(
        alpha3: 'CXR',
        alpha2: 'CX',
        numericCode: 162,
        name: 'Christmas Island'),
    'CCK': Country(
        alpha3: 'CCK',
        alpha2: 'CC',
        numericCode: 166,
        name: 'Cocos (Keeling) Islands'),
    'COL': Country(
        alpha3: 'COL', alpha2: 'CO', numericCode: 170, name: 'Colombia'),
    'COM':
        Country(alpha3: 'COM', alpha2: 'KM', numericCode: 174, name: 'Comoros'),
    'COG':
        Country(alpha3: 'COG', alpha2: 'CG', numericCode: 178, name: 'Congo'),
    'COD': Country(
        alpha3: 'COD',
        alpha2: 'CD',
        numericCode: 180,
        name: 'Congo, Democratic Republic of the'),
    'COK': Country(
        alpha3: 'COK', alpha2: 'CK', numericCode: 184, name: 'Cook Islands'),
    'CRI': Country(
        alpha3: 'CRI', alpha2: 'CR', numericCode: 188, name: 'Costa Rica'),
    'CIV': Country(
        alpha3: 'CIV', alpha2: 'CI', numericCode: 384, name: 'Côte d\'Ivoire'),
    'HRV':
        Country(alpha3: 'HRV', alpha2: 'HR', numericCode: 191, name: 'Croatia'),
    'CUB': Country(alpha3: 'CUB', alpha2: 'CU', numericCode: 192, name: 'Cuba'),
    'CUW':
        Country(alpha3: 'CUW', alpha2: 'CW', numericCode: 531, name: 'Curaçao'),
    'CYP':
        Country(alpha3: 'CYP', alpha2: 'CY', numericCode: 196, name: 'Cyprus'),
    'CZE':
        Country(alpha3: 'CZE', alpha2: 'CZ', numericCode: 203, name: 'Czechia'),
    'DNK':
        Country(alpha3: 'DNK', alpha2: 'DK', numericCode: 208, name: 'Denmark'),
    'DJI': Country(
        alpha3: 'DJI', alpha2: 'DJ', numericCode: 262, name: 'Djibouti'),
    'DMA': Country(
        alpha3: 'DMA', alpha2: 'DM', numericCode: 212, name: 'Dominica'),
    'DOM': Country(
        alpha3: 'DOM',
        alpha2: 'DO',
        numericCode: 214,
        name: 'Dominican Republic'),
    'ECU':
        Country(alpha3: 'ECU', alpha2: 'EC', numericCode: 218, name: 'Ecuador'),
    'EGY':
        Country(alpha3: 'EGY', alpha2: 'EG', numericCode: 818, name: 'Egypt'),
    'SLV': Country(
        alpha3: 'SLV', alpha2: 'SV', numericCode: 222, name: 'El Salvador'),
    'GNQ': Country(
        alpha3: 'GNQ',
        alpha2: 'GQ',
        numericCode: 226,
        name: 'Equatorial Guinea'),
    'ERI':
        Country(alpha3: 'ERI', alpha2: 'ER', numericCode: 232, name: 'Eritrea'),
    'EST':
        Country(alpha3: 'EST', alpha2: 'EE', numericCode: 233, name: 'Estonia'),
    'SWZ': Country(
        alpha3: 'SWZ', alpha2: 'SZ', numericCode: 748, name: 'Eswatini'),
    'ETH': Country(
        alpha3: 'ETH', alpha2: 'ET', numericCode: 231, name: 'Ethiopia'),
    'FLK': Country(
        alpha3: 'FLK',
        alpha2: 'FK',
        numericCode: 238,
        name: 'Falkland Islands (Malvinas)'),
    'FRO': Country(
        alpha3: 'FRO', alpha2: 'FO', numericCode: 234, name: 'Faroe Islands'),
    'FJI': Country(alpha3: 'FJI', alpha2: 'FJ', numericCode: 242, name: 'Fiji'),
    'FIN':
        Country(alpha3: 'FIN', alpha2: 'FI', numericCode: 246, name: 'Finland'),
    'FRA':
        Country(alpha3: 'FRA', alpha2: 'FR', numericCode: 250, name: 'France'),
    'GUF': Country(
        alpha3: 'GUF', alpha2: 'GF', numericCode: 254, name: 'French Guiana'),
    'PYF': Country(
        alpha3: 'PYF',
        alpha2: 'PF',
        numericCode: 258,
        name: 'French Polynesia'),
    'ATF': Country(
        alpha3: 'ATF',
        alpha2: 'TF',
        numericCode: 260,
        name: 'French Southern Territories'),
    'GAB':
        Country(alpha3: 'GAB', alpha2: 'GA', numericCode: 266, name: 'Gabon'),
    'GMB':
        Country(alpha3: 'GMB', alpha2: 'GM', numericCode: 270, name: 'Gambia'),
    'GEO':
        Country(alpha3: 'GEO', alpha2: 'GE', numericCode: 268, name: 'Georgia'),
    'DEU':
        Country(alpha3: 'DEU', alpha2: 'DE', numericCode: 276, name: 'Germany'),
    'GHA':
        Country(alpha3: 'GHA', alpha2: 'GH', numericCode: 288, name: 'Ghana'),
    'GIB': Country(
        alpha3: 'GIB', alpha2: 'GI', numericCode: 292, name: 'Gibraltar'),
    'GRC':
        Country(alpha3: 'GRC', alpha2: 'GR', numericCode: 300, name: 'Greece'),
    'GRL': Country(
        alpha3: 'GRL', alpha2: 'GL', numericCode: 304, name: 'Greenland'),
    'GRD':
        Country(alpha3: 'GRD', alpha2: 'GD', numericCode: 308, name: 'Grenada'),
    'GLP': Country(
        alpha3: 'GLP', alpha2: 'GP', numericCode: 312, name: 'Guadeloupe'),
    'GUM': Country(alpha3: 'GUM', alpha2: 'GU', numericCode: 316, name: 'Guam'),
    'GTM': Country(
        alpha3: 'GTM', alpha2: 'GT', numericCode: 320, name: 'Guatemala'),
    'GGY': Country(
        alpha3: 'GGY', alpha2: 'GG', numericCode: 831, name: 'Guernsey'),
    'GIN':
        Country(alpha3: 'GIN', alpha2: 'GN', numericCode: 324, name: 'Guinea'),
    'GNB': Country(
        alpha3: 'GNB', alpha2: 'GW', numericCode: 624, name: 'Guinea-Bissau'),
    'GUY':
        Country(alpha3: 'GUY', alpha2: 'GY', numericCode: 328, name: 'Guyana'),
    'HTI':
        Country(alpha3: 'HTI', alpha2: 'HT', numericCode: 332, name: 'Haiti'),
    'HMD': Country(
        alpha3: 'HMD',
        alpha2: 'HM',
        numericCode: 334,
        name: 'Heard Island and McDonald Islands'),
    'VAT': Country(
        alpha3: 'VAT', alpha2: 'VA', numericCode: 336, name: 'Holy See'),
    'HND': Country(
        alpha3: 'HND', alpha2: 'HN', numericCode: 340, name: 'Honduras'),
    'HKG': Country(
        alpha3: 'HKG', alpha2: 'HK', numericCode: 344, name: 'Hong Kong'),
    'HUN':
        Country(alpha3: 'HUN', alpha2: 'HU', numericCode: 348, name: 'Hungary'),
    'ISL':
        Country(alpha3: 'ISL', alpha2: 'IS', numericCode: 352, name: 'Iceland'),
    'IND':
        Country(alpha3: 'IND', alpha2: 'IN', numericCode: 356, name: 'India'),
    'IDN': Country(
        alpha3: 'IDN', alpha2: 'ID', numericCode: 360, name: 'Indonesia'),
    'IRN': Country(
        alpha3: 'IRN',
        alpha2: 'IR',
        numericCode: 364,
        name: 'Iran (Islamic Republic of)'),
    'IRQ': Country(alpha3: 'IRQ', alpha2: 'IQ', numericCode: 368, name: 'Iraq'),
    'IRL':
        Country(alpha3: 'IRL', alpha2: 'IE', numericCode: 372, name: 'Ireland'),
    'IMN': Country(
        alpha3: 'IMN', alpha2: 'IM', numericCode: 833, name: 'Isle of Man'),
    'ISR':
        Country(alpha3: 'ISR', alpha2: 'IL', numericCode: 376, name: 'Israel'),
    'ITA':
        Country(alpha3: 'ITA', alpha2: 'IT', numericCode: 380, name: 'Italy'),
    'JAM':
        Country(alpha3: 'JAM', alpha2: 'JM', numericCode: 388, name: 'Jamaica'),
    'JPN':
        Country(alpha3: 'JPN', alpha2: 'JP', numericCode: 392, name: 'Japan'),
    'JEY':
        Country(alpha3: 'JEY', alpha2: 'JE', numericCode: 832, name: 'Jersey'),
    'JOR':
        Country(alpha3: 'JOR', alpha2: 'JO', numericCode: 400, name: 'Jordan'),
    'KAZ': Country(
        alpha3: 'KAZ', alpha2: 'KZ', numericCode: 398, name: 'Kazakhstan'),
    'KEN':
        Country(alpha3: 'KEN', alpha2: 'KE', numericCode: 404, name: 'Kenya'),
    'KIR': Country(
        alpha3: 'KIR', alpha2: 'KI', numericCode: 296, name: 'Kiribati'),
    'PRK': Country(
        alpha3: 'PRK',
        alpha2: 'KP',
        numericCode: 408,
        name: 'Korea (Democratic People\'s Republic of)'),
    'KOR': Country(
        alpha3: 'KOR',
        alpha2: 'KR',
        numericCode: 410,
        name: 'Korea, Republic of'),
    'KWT':
        Country(alpha3: 'KWT', alpha2: 'KW', numericCode: 414, name: 'Kuwait'),
    'KGZ': Country(
        alpha3: 'KGZ', alpha2: 'KG', numericCode: 417, name: 'Kyrgyzstan'),
    'LAO': Country(
        alpha3: 'LAO',
        alpha2: 'LA',
        numericCode: 418,
        name: 'Lao People\'s Democratic Republic'),
    'LVA':
        Country(alpha3: 'LVA', alpha2: 'LV', numericCode: 428, name: 'Latvia'),
    'LBN':
        Country(alpha3: 'LBN', alpha2: 'LB', numericCode: 422, name: 'Lebanon'),
    'LSO':
        Country(alpha3: 'LSO', alpha2: 'LS', numericCode: 426, name: 'Lesotho'),
    'LBR':
        Country(alpha3: 'LBR', alpha2: 'LR', numericCode: 430, name: 'Liberia'),
    'LBY':
        Country(alpha3: 'LBY', alpha2: 'LY', numericCode: 434, name: 'Libya'),
    'LIE': Country(
        alpha3: 'LIE', alpha2: 'LI', numericCode: 438, name: 'Liechtenstein'),
    'LTU': Country(
        alpha3: 'LTU', alpha2: 'LT', numericCode: 440, name: 'Lithuania'),
    'LUX': Country(
        alpha3: 'LUX', alpha2: 'LU', numericCode: 442, name: 'Luxembourg'),
    'MAC':
        Country(alpha3: 'MAC', alpha2: 'MO', numericCode: 446, name: 'Macao'),
    'MDG': Country(
        alpha3: 'MDG', alpha2: 'MG', numericCode: 450, name: 'Madagascar'),
    'MWI':
        Country(alpha3: 'MWI', alpha2: 'MW', numericCode: 454, name: 'Malawi'),
    'MYS': Country(
        alpha3: 'MYS', alpha2: 'MY', numericCode: 458, name: 'Malaysia'),
    'MDV': Country(
        alpha3: 'MDV', alpha2: 'MV', numericCode: 462, name: 'Maldives'),
    'MLI': Country(alpha3: 'MLI', alpha2: 'ML', numericCode: 466, name: 'Mali'),
    'MLT':
        Country(alpha3: 'MLT', alpha2: 'MT', numericCode: 470, name: 'Malta'),
    'MHL': Country(
        alpha3: 'MHL',
        alpha2: 'MH',
        numericCode: 584,
        name: 'Marshall Islands'),
    'MTQ': Country(
        alpha3: 'MTQ', alpha2: 'MQ', numericCode: 474, name: 'Martinique'),
    'MRT': Country(
        alpha3: 'MRT', alpha2: 'MR', numericCode: 478, name: 'Mauritania'),
    'MUS': Country(
        alpha3: 'MUS', alpha2: 'MU', numericCode: 480, name: 'Mauritius'),
    'MYT':
        Country(alpha3: 'MYT', alpha2: 'YT', numericCode: 175, name: 'Mayotte'),
    'MEX':
        Country(alpha3: 'MEX', alpha2: 'MX', numericCode: 484, name: 'Mexico'),
    'FSM': Country(
        alpha3: 'FSM',
        alpha2: 'FM',
        numericCode: 583,
        name: 'Micronesia (Federated States of)'),
    'MDA': Country(
        alpha3: 'MDA',
        alpha2: 'MD',
        numericCode: 498,
        name: 'Moldova, Republic of'),
    'MCO':
        Country(alpha3: 'MCO', alpha2: 'MC', numericCode: 492, name: 'Monaco'),
    'MNG': Country(
        alpha3: 'MNG', alpha2: 'MN', numericCode: 496, name: 'Mongolia'),
    'MNE': Country(
        alpha3: 'MNE', alpha2: 'ME', numericCode: 499, name: 'Montenegro'),
    'MSR': Country(
        alpha3: 'MSR', alpha2: 'MS', numericCode: 500, name: 'Montserrat'),
    'MAR':
        Country(alpha3: 'MAR', alpha2: 'MA', numericCode: 504, name: 'Morocco'),
    'MOZ': Country(
        alpha3: 'MOZ', alpha2: 'MZ', numericCode: 508, name: 'Mozambique'),
    'MMR':
        Country(alpha3: 'MMR', alpha2: 'MM', numericCode: 104, name: 'Myanmar'),
    'NAM':
        Country(alpha3: 'NAM', alpha2: 'NA', numericCode: 516, name: 'Namibia'),
    'NRU':
        Country(alpha3: 'NRU', alpha2: 'NR', numericCode: 520, name: 'Nauru'),
    'NPL':
        Country(alpha3: 'NPL', alpha2: 'NP', numericCode: 524, name: 'Nepal'),
    'NLD': Country(
        alpha3: 'NLD', alpha2: 'NL', numericCode: 528, name: 'Netherlands'),
    'NCL': Country(
        alpha3: 'NCL', alpha2: 'NC', numericCode: 540, name: 'New Caledonia'),
    'NZL': Country(
        alpha3: 'NZL', alpha2: 'NZ', numericCode: 554, name: 'New Zealand'),
    'NIC': Country(
        alpha3: 'NIC', alpha2: 'NI', numericCode: 558, name: 'Nicaragua'),
    'NER':
        Country(alpha3: 'NER', alpha2: 'NE', numericCode: 562, name: 'Niger'),
    'NGA':
        Country(alpha3: 'NGA', alpha2: 'NG', numericCode: 566, name: 'Nigeria'),
    'NIU': Country(alpha3: 'NIU', alpha2: 'NU', numericCode: 570, name: 'Niue'),
    'NFK': Country(
        alpha3: 'NFK', alpha2: 'NF', numericCode: 574, name: 'Norfolk Island'),
    'MKD': Country(
        alpha3: 'MKD', alpha2: 'MK', numericCode: 807, name: 'North Macedonia'),
    'MNP': Country(
        alpha3: 'MNP',
        alpha2: 'MP',
        numericCode: 580,
        name: 'Northern Mariana Islands'),
    'NOR':
        Country(alpha3: 'NOR', alpha2: 'NO', numericCode: 578, name: 'Norway'),
    'OMN': Country(alpha3: 'OMN', alpha2: 'OM', numericCode: 512, name: 'Oman'),
    'PAK': Country(
        alpha3: 'PAK', alpha2: 'PK', numericCode: 586, name: 'Pakistan'),
    'PLW':
        Country(alpha3: 'PLW', alpha2: 'PW', numericCode: 585, name: 'Palau'),
    'PSE': Country(
        alpha3: 'PSE',
        alpha2: 'PS',
        numericCode: 275,
        name: 'Palestine, State of'),
    'PAN':
        Country(alpha3: 'PAN', alpha2: 'PA', numericCode: 591, name: 'Panama'),
    'PNG': Country(
        alpha3: 'PNG',
        alpha2: 'PG',
        numericCode: 598,
        name: 'Papua New Guinea'),
    'PRY': Country(
        alpha3: 'PRY', alpha2: 'PY', numericCode: 600, name: 'Paraguay'),
    'PER': Country(alpha3: 'PER', alpha2: 'PE', numericCode: 604, name: 'Peru'),
    'PHL': Country(
        alpha3: 'PHL', alpha2: 'PH', numericCode: 608, name: 'Philippines'),
    'PCN': Country(
        alpha3: 'PCN', alpha2: 'PN', numericCode: 612, name: 'Pitcairn'),
    'POL':
        Country(alpha3: 'POL', alpha2: 'PL', numericCode: 616, name: 'Poland'),
    'PRT': Country(
        alpha3: 'PRT', alpha2: 'PT', numericCode: 620, name: 'Portugal'),
    'PRI': Country(
        alpha3: 'PRI', alpha2: 'PR', numericCode: 630, name: 'Puerto Rico'),
    'QAT':
        Country(alpha3: 'QAT', alpha2: 'QA', numericCode: 634, name: 'Qatar'),
    'REU':
        Country(alpha3: 'REU', alpha2: 'RE', numericCode: 638, name: 'Réunion'),
    'ROU':
        Country(alpha3: 'ROU', alpha2: 'RO', numericCode: 642, name: 'Romania'),
    'RUS': Country(
        alpha3: 'RUS',
        alpha2: 'RU',
        numericCode: 643,
        name: 'Russian Federation'),
    'RWA':
        Country(alpha3: 'RWA', alpha2: 'RW', numericCode: 646, name: 'Rwanda'),
    'BLM': Country(
        alpha3: 'BLM',
        alpha2: 'BL',
        numericCode: 652,
        name: 'Saint Barthélemy'),
    'SHN': Country(
        alpha3: 'SHN',
        alpha2: 'SH',
        numericCode: 654,
        name: 'Saint Helena, Ascension and Tristan da Cunha[e]'),
    'KNA': Country(
        alpha3: 'KNA',
        alpha2: 'KN',
        numericCode: 659,
        name: 'Saint Kitts and Nevis'),
    'LCA': Country(
        alpha3: 'LCA', alpha2: 'LC', numericCode: 662, name: 'Saint Lucia'),
    'MAF': Country(
        alpha3: 'MAF',
        alpha2: 'MF',
        numericCode: 663,
        name: 'Saint Martin (French part)'),
    'SPM': Country(
        alpha3: 'SPM',
        alpha2: 'PM',
        numericCode: 666,
        name: 'Saint Pierre and Miquelon'),
    'VCT': Country(
        alpha3: 'VCT',
        alpha2: 'VC',
        numericCode: 670,
        name: 'Saint Vincent and the Grenadines'),
    'WSM':
        Country(alpha3: 'WSM', alpha2: 'WS', numericCode: 882, name: 'Samoa'),
    'SMR': Country(
        alpha3: 'SMR', alpha2: 'SM', numericCode: 674, name: 'San Marino'),
    'STP': Country(
        alpha3: 'STP',
        alpha2: 'ST',
        numericCode: 678,
        name: 'Sao Tome and Principe'),
    'SAU': Country(
        alpha3: 'SAU', alpha2: 'SA', numericCode: 682, name: 'Saudi Arabia'),
    'SEN':
        Country(alpha3: 'SEN', alpha2: 'SN', numericCode: 686, name: 'Senegal'),
    'SRB':
        Country(alpha3: 'SRB', alpha2: 'RS', numericCode: 688, name: 'Serbia'),
    'SYC': Country(
        alpha3: 'SYC', alpha2: 'SC', numericCode: 690, name: 'Seychelles'),
    'SLE': Country(
        alpha3: 'SLE', alpha2: 'SL', numericCode: 694, name: 'Sierra Leone'),
    'SGP': Country(
        alpha3: 'SGP', alpha2: 'SG', numericCode: 702, name: 'Singapore'),
    'SXM': Country(
        alpha3: 'SXM',
        alpha2: 'SX',
        numericCode: 534,
        name: 'Sint Maarten (Dutch part)'),
    'SVK': Country(
        alpha3: 'SVK', alpha2: 'SK', numericCode: 703, name: 'Slovakia'),
    'SVN': Country(
        alpha3: 'SVN', alpha2: 'SI', numericCode: 705, name: 'Slovenia'),
    'SLB': Country(
        alpha3: 'SLB', alpha2: 'SB', numericCode: 90, name: 'Solomon Islands'),
    'SOM':
        Country(alpha3: 'SOM', alpha2: 'SO', numericCode: 706, name: 'Somalia'),
    'ZAF': Country(
        alpha3: 'ZAF', alpha2: 'ZA', numericCode: 710, name: 'South Africa'),
    'SGS': Country(
        alpha3: 'SGS',
        alpha2: 'GS',
        numericCode: 239,
        name: 'South Georgia and the South Sandwich Islands'),
    'SSD': Country(
        alpha3: 'SSD', alpha2: 'SS', numericCode: 728, name: 'South Sudan'),
    'ESP':
        Country(alpha3: 'ESP', alpha2: 'ES', numericCode: 724, name: 'Spain'),
    'LKA': Country(
        alpha3: 'LKA', alpha2: 'LK', numericCode: 144, name: 'Sri Lanka'),
    'SDN':
        Country(alpha3: 'SDN', alpha2: 'SD', numericCode: 729, name: 'Sudan'),
    'SUR': Country(
        alpha3: 'SUR', alpha2: 'SR', numericCode: 740, name: 'Suriname'),
    'SJM': Country(
        alpha3: 'SJM',
        alpha2: 'SJ',
        numericCode: 744,
        name: 'Svalbard and Jan Mayen[f]'),
    'SWE':
        Country(alpha3: 'SWE', alpha2: 'SE', numericCode: 752, name: 'Sweden'),
    'CHE': Country(
        alpha3: 'CHE', alpha2: 'CH', numericCode: 756, name: 'Switzerland'),
    'SYR': Country(
        alpha3: 'SYR',
        alpha2: 'SY',
        numericCode: 760,
        name: 'Syrian Arab Republic'),
    'TWN': Country(
        alpha3: 'TWN',
        alpha2: 'TW',
        numericCode: 158,
        name: 'Taiwan, Province of China'),
    'TJK': Country(
        alpha3: 'TJK', alpha2: 'TJ', numericCode: 762, name: 'Tajikistan'),
    'TZA': Country(
        alpha3: 'TZA',
        alpha2: 'TZ',
        numericCode: 834,
        name: 'Tanzania, United Republic of'),
    'THA': Country(
        alpha3: 'THA', alpha2: 'TH', numericCode: 764, name: 'Thailand'),
    'TLS': Country(
        alpha3: 'TLS', alpha2: 'TL', numericCode: 626, name: 'Timor-Leste'),
    'TGO': Country(alpha3: 'TGO', alpha2: 'TG', numericCode: 768, name: 'Togo'),
    'TKL':
        Country(alpha3: 'TKL', alpha2: 'TK', numericCode: 772, name: 'Tokelau'),
    'TON':
        Country(alpha3: 'TON', alpha2: 'TO', numericCode: 776, name: 'Tonga'),
    'TTO': Country(
        alpha3: 'TTO',
        alpha2: 'TT',
        numericCode: 780,
        name: 'Trinidad and Tobago'),
    'TUN':
        Country(alpha3: 'TUN', alpha2: 'TN', numericCode: 788, name: 'Tunisia'),
    'TUR':
        Country(alpha3: 'TUR', alpha2: 'TR', numericCode: 792, name: 'Turkey'),
    'TKM': Country(
        alpha3: 'TKM', alpha2: 'TM', numericCode: 795, name: 'Turkmenistan'),
    'TCA': Country(
        alpha3: 'TCA',
        alpha2: 'TC',
        numericCode: 796,
        name: 'Turks and Caicos Islands'),
    'TUV':
        Country(alpha3: 'TUV', alpha2: 'TV', numericCode: 798, name: 'Tuvalu'),
    'UGA':
        Country(alpha3: 'UGA', alpha2: 'UG', numericCode: 800, name: 'Uganda'),
    'UKR':
        Country(alpha3: 'UKR', alpha2: 'UA', numericCode: 804, name: 'Ukraine'),
    'ARE': Country(
        alpha3: 'ARE',
        alpha2: 'AE',
        numericCode: 784,
        name: 'United Arab Emirates'),
    'GBR': Country(
        alpha3: 'GBR',
        alpha2: 'GB',
        numericCode: 826,
        name: 'United Kingdom of Great Britain and Northern Ireland'),
    'USA': Country(
        alpha3: 'USA',
        alpha2: 'US',
        numericCode: 840,
        name: 'United States of America'),
    'UMI': Country(
        alpha3: 'UMI',
        alpha2: 'UM',
        numericCode: 581,
        name: 'United States Minor Outlying Islands[h]'),
    'URY':
        Country(alpha3: 'URY', alpha2: 'UY', numericCode: 858, name: 'Uruguay'),
    'UZB': Country(
        alpha3: 'UZB', alpha2: 'UZ', numericCode: 860, name: 'Uzbekistan'),
    'VUT':
        Country(alpha3: 'VUT', alpha2: 'VU', numericCode: 548, name: 'Vanuatu'),
    'VEN': Country(
        alpha3: 'VEN',
        alpha2: 'VE',
        numericCode: 862,
        name: 'Venezuela (Bolivarian Republic of)'),
    'VNM': Country(
        alpha3: 'VNM', alpha2: 'VN', numericCode: 704, name: 'Viet Nam'),
    'VGB': Country(
        alpha3: 'VGB',
        alpha2: 'VG',
        numericCode: 92,
        name: 'Virgin Islands (British)'),
    'VIR': Country(
        alpha3: 'VIR',
        alpha2: 'VI',
        numericCode: 850,
        name: 'Virgin Islands (U.S.)'),
    'WLF': Country(
        alpha3: 'WLF',
        alpha2: 'WF',
        numericCode: 876,
        name: 'Wallis and Futuna'),
    'ESH': Country(
        alpha3: 'ESH', alpha2: 'EH', numericCode: 732, name: 'Western Sahara'),
    'YEM':
        Country(alpha3: 'YEM', alpha2: 'YE', numericCode: 887, name: 'Yemen'),
    'ZMB':
        Country(alpha3: 'ZMB', alpha2: 'ZM', numericCode: 894, name: 'Zambia'),
    'ZWE': Country(
        alpha3: 'ZWE', alpha2: 'ZW', numericCode: 716, name: 'Zimbabwe'),
  };

  /// Mapping of all countries by alpha-3 code
  static Map<String, Country> countries2 = {
    'AF': countries3['AFG']!,
    'AX': countries3['ALA']!,
    'AL': countries3['ALB']!,
    'DZ': countries3['DZA']!,
    'AS': countries3['ASM']!,
    'AD': countries3['AND']!,
    'AO': countries3['AGO']!,
    'AI': countries3['AIA']!,
    'AQ': countries3['ATA']!,
    'AG': countries3['ATG']!,
    'AR': countries3['ARG']!,
    'AM': countries3['ARM']!,
    'AW': countries3['ABW']!,
    'AU': countries3['AUS']!,
    'AT': countries3['AUT']!,
    'AZ': countries3['AZE']!,
    'BS': countries3['BHS']!,
    'BH': countries3['BHR']!,
    'BD': countries3['BGD']!,
    'BB': countries3['BRB']!,
    'BY': countries3['BLR']!,
    'BE': countries3['BEL']!,
    'BZ': countries3['BLZ']!,
    'BJ': countries3['BEN']!,
    'BM': countries3['BMU']!,
    'BT': countries3['BTN']!,
    'BO': countries3['BOL']!,
    'BQ': countries3['BES']!,
    'BA': countries3['BIH']!,
    'BW': countries3['BWA']!,
    'BV': countries3['BVT']!,
    'BR': countries3['BRA']!,
    'IO': countries3['IOT']!,
    'BN': countries3['BRN']!,
    'BG': countries3['BGR']!,
    'BF': countries3['BFA']!,
    'BI': countries3['BDI']!,
    'CV': countries3['CPV']!,
    'KH': countries3['KHM']!,
    'CM': countries3['CMR']!,
    'CA': countries3['CAN']!,
    'KY': countries3['CYM']!,
    'CF': countries3['CAF']!,
    'TD': countries3['TCD']!,
    'CL': countries3['CHL']!,
    'CN': countries3['CHN']!,
    'CX': countries3['CXR']!,
    'CC': countries3['CCK']!,
    'CO': countries3['COL']!,
    'KM': countries3['COM']!,
    'CG': countries3['COG']!,
    'CD': countries3['COD']!,
    'CK': countries3['COK']!,
    'CR': countries3['CRI']!,
    'CI': countries3['CIV']!,
    'HR': countries3['HRV']!,
    'CU': countries3['CUB']!,
    'CW': countries3['CUW']!,
    'CY': countries3['CYP']!,
    'CZ': countries3['CZE']!,
    'DK': countries3['DNK']!,
    'DJ': countries3['DJI']!,
    'DM': countries3['DMA']!,
    'DO': countries3['DOM']!,
    'EC': countries3['ECU']!,
    'EG': countries3['EGY']!,
    'SV': countries3['SLV']!,
    'GQ': countries3['GNQ']!,
    'ER': countries3['ERI']!,
    'EE': countries3['EST']!,
    'SZ': countries3['SWZ']!,
    'ET': countries3['ETH']!,
    'FK': countries3['FLK']!,
    'FO': countries3['FRO']!,
    'FJ': countries3['FJI']!,
    'FI': countries3['FIN']!,
    'FR': countries3['FRA']!,
    'GF': countries3['GUF']!,
    'PF': countries3['PYF']!,
    'TF': countries3['ATF']!,
    'GA': countries3['GAB']!,
    'GM': countries3['GMB']!,
    'GE': countries3['GEO']!,
    'DE': countries3['DEU']!,
    'GH': countries3['GHA']!,
    'GI': countries3['GIB']!,
    'GR': countries3['GRC']!,
    'GL': countries3['GRL']!,
    'GD': countries3['GRD']!,
    'GP': countries3['GLP']!,
    'GU': countries3['GUM']!,
    'GT': countries3['GTM']!,
    'GG': countries3['GGY']!,
    'GN': countries3['GIN']!,
    'GW': countries3['GNB']!,
    'GY': countries3['GUY']!,
    'HT': countries3['HTI']!,
    'HM': countries3['HMD']!,
    'VA': countries3['VAT']!,
    'HN': countries3['HND']!,
    'HK': countries3['HKG']!,
    'HU': countries3['HUN']!,
    'IS': countries3['ISL']!,
    'IN': countries3['IND']!,
    'ID': countries3['IDN']!,
    'IR': countries3['IRN']!,
    'IQ': countries3['IRQ']!,
    'IE': countries3['IRL']!,
    'IM': countries3['IMN']!,
    'IL': countries3['ISR']!,
    'IT': countries3['ITA']!,
    'JM': countries3['JAM']!,
    'JP': countries3['JPN']!,
    'JE': countries3['JEY']!,
    'JO': countries3['JOR']!,
    'KZ': countries3['KAZ']!,
    'KE': countries3['KEN']!,
    'KI': countries3['KIR']!,
    'KP': countries3['PRK']!,
    'KR': countries3['KOR']!,
    'KW': countries3['KWT']!,
    'KG': countries3['KGZ']!,
    'LA': countries3['LAO']!,
    'LV': countries3['LVA']!,
    'LB': countries3['LBN']!,
    'LS': countries3['LSO']!,
    'LR': countries3['LBR']!,
    'LY': countries3['LBY']!,
    'LI': countries3['LIE']!,
    'LT': countries3['LTU']!,
    'LU': countries3['LUX']!,
    'MO': countries3['MAC']!,
    'MG': countries3['MDG']!,
    'MW': countries3['MWI']!,
    'MY': countries3['MYS']!,
    'MV': countries3['MDV']!,
    'ML': countries3['MLI']!,
    'MT': countries3['MLT']!,
    'MH': countries3['MHL']!,
    'MQ': countries3['MTQ']!,
    'MR': countries3['MRT']!,
    'MU': countries3['MUS']!,
    'YT': countries3['MYT']!,
    'MX': countries3['MEX']!,
    'FM': countries3['FSM']!,
    'MD': countries3['MDA']!,
    'MC': countries3['MCO']!,
    'MN': countries3['MNG']!,
    'ME': countries3['MNE']!,
    'MS': countries3['MSR']!,
    'MA': countries3['MAR']!,
    'MZ': countries3['MOZ']!,
    'MM': countries3['MMR']!,
    'NA': countries3['NAM']!,
    'NR': countries3['NRU']!,
    'NP': countries3['NPL']!,
    'NL': countries3['NLD']!,
    'NC': countries3['NCL']!,
    'NZ': countries3['NZL']!,
    'NI': countries3['NIC']!,
    'NE': countries3['NER']!,
    'NG': countries3['NGA']!,
    'NU': countries3['NIU']!,
    'NF': countries3['NFK']!,
    'MK': countries3['MKD']!,
    'MP': countries3['MNP']!,
    'NO': countries3['NOR']!,
    'OM': countries3['OMN']!,
    'PK': countries3['PAK']!,
    'PW': countries3['PLW']!,
    'PS': countries3['PSE']!,
    'PA': countries3['PAN']!,
    'PG': countries3['PNG']!,
    'PY': countries3['PRY']!,
    'PE': countries3['PER']!,
    'PH': countries3['PHL']!,
    'PN': countries3['PCN']!,
    'PL': countries3['POL']!,
    'PT': countries3['PRT']!,
    'PR': countries3['PRI']!,
    'QA': countries3['QAT']!,
    'RE': countries3['REU']!,
    'RO': countries3['ROU']!,
    'RU': countries3['RUS']!,
    'RW': countries3['RWA']!,
    'BL': countries3['BLM']!,
    'SH': countries3['SHN']!,
    'KN': countries3['KNA']!,
    'LC': countries3['LCA']!,
    'MF': countries3['MAF']!,
    'PM': countries3['SPM']!,
    'VC': countries3['VCT']!,
    'WS': countries3['WSM']!,
    'SM': countries3['SMR']!,
    'ST': countries3['STP']!,
    'SA': countries3['SAU']!,
    'SN': countries3['SEN']!,
    'RS': countries3['SRB']!,
    'SC': countries3['SYC']!,
    'SL': countries3['SLE']!,
    'SG': countries3['SGP']!,
    'SX': countries3['SXM']!,
    'SK': countries3['SVK']!,
    'SI': countries3['SVN']!,
    'SB': countries3['SLB']!,
    'SO': countries3['SOM']!,
    'ZA': countries3['ZAF']!,
    'GS': countries3['SGS']!,
    'SS': countries3['SSD']!,
    'ES': countries3['ESP']!,
    'LK': countries3['LKA']!,
    'SD': countries3['SDN']!,
    'SR': countries3['SUR']!,
    'SJ': countries3['SJM']!,
    'SE': countries3['SWE']!,
    'CH': countries3['CHE']!,
    'SY': countries3['SYR']!,
    'TW': countries3['TWN']!,
    'TJ': countries3['TJK']!,
    'TZ': countries3['TZA']!,
    'TH': countries3['THA']!,
    'TL': countries3['TLS']!,
    'TG': countries3['TGO']!,
    'TK': countries3['TKL']!,
    'TO': countries3['TON']!,
    'TT': countries3['TTO']!,
    'TN': countries3['TUN']!,
    'TR': countries3['TUR']!,
    'TM': countries3['TKM']!,
    'TC': countries3['TCA']!,
    'TV': countries3['TUV']!,
    'UG': countries3['UGA']!,
    'UA': countries3['UKR']!,
    'AE': countries3['ARE']!,
    'GB': countries3['GBR']!,
    'US': countries3['USA']!,
    'UM': countries3['UMI']!,
    'UY': countries3['URY']!,
    'UZ': countries3['UZB']!,
    'VU': countries3['VUT']!,
    'VE': countries3['VEN']!,
    'VN': countries3['VNM']!,
    'VG': countries3['VGB']!,
    'VI': countries3['VIR']!,
    'WF': countries3['WLF']!,
    'EH': countries3['ESH']!,
    'YE': countries3['YEM']!,
    'ZM': countries3['ZMB']!,
    'ZW': countries3['ZWE']!,
  };
}
