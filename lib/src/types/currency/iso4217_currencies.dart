class Currency {
  int numericCode;
  int? minorUnit;
  String name;

  Currency({this.numericCode = 0, this.minorUnit, this.name = ''});

  @override
  bool operator ==(other) =>
      other is Currency &&
      other.numericCode == numericCode &&
      other.minorUnit == minorUnit &&
      other.name == name;

  @override
  int get hashCode => [numericCode, minorUnit, name].hashCode;

  @override
  String toString() =>
      "numericCode:$numericCode minorUnit:$minorUnit name:$name";

  static Map<String, Currency> currencies = {
    'AED': Currency(
        numericCode: 784, minorUnit: 2, name: 'United Arab Emirates dirham'),
    'AFN': Currency(numericCode: 971, minorUnit: 2, name: 'Afghan afghani'),
    'ALL': Currency(numericCode: 8, minorUnit: 2, name: 'Albanian lek'),
    'AMD': Currency(numericCode: 51, minorUnit: 2, name: 'Armenian dram'),
    'ANG': Currency(
        numericCode: 532, minorUnit: 2, name: 'Netherlands Antillean guilder'),
    'AOA': Currency(numericCode: 973, minorUnit: 2, name: 'Angolan kwanza'),
    'ARS': Currency(numericCode: 32, minorUnit: 2, name: 'Argentine peso'),
    'AUD': Currency(numericCode: 36, minorUnit: 2, name: 'Australian dollar'),
    'AWG': Currency(numericCode: 533, minorUnit: 2, name: 'Aruban florin'),
    'AZN': Currency(numericCode: 944, minorUnit: 2, name: 'Azerbaijani manat'),
    'BAM': Currency(
        numericCode: 977,
        minorUnit: 2,
        name: 'Bosnia and Herzegovina convertible mark'),
    'BBD': Currency(numericCode: 52, minorUnit: 2, name: 'Barbados dollar'),
    'BDT': Currency(numericCode: 50, minorUnit: 2, name: 'Bangladeshi taka'),
    'BGN': Currency(numericCode: 975, minorUnit: 2, name: 'Bulgarian lev'),
    'BHD': Currency(numericCode: 48, minorUnit: 3, name: 'Bahraini dinar'),
    'BIF': Currency(numericCode: 108, minorUnit: 0, name: 'Burundian franc'),
    'BMD': Currency(numericCode: 60, minorUnit: 2, name: 'Bermudian dollar'),
    'BND': Currency(numericCode: 96, minorUnit: 2, name: 'Brunei dollar'),
    'BOB': Currency(numericCode: 68, minorUnit: 2, name: 'Boliviano'),
    'BOV': Currency(
        numericCode: 984, minorUnit: 2, name: 'Bolivian Mvdol (funds code)'),
    'BRL': Currency(numericCode: 986, minorUnit: 2, name: 'Brazilian real'),
    'BSD': Currency(numericCode: 44, minorUnit: 2, name: 'Bahamian dollar'),
    'BTN': Currency(numericCode: 64, minorUnit: 2, name: 'Bhutanese ngultrum'),
    'BWP': Currency(numericCode: 72, minorUnit: 2, name: 'Botswana pula'),
    'BYN': Currency(numericCode: 933, minorUnit: 2, name: 'Belarusian ruble'),
    'BZD': Currency(numericCode: 84, minorUnit: 2, name: 'Belize dollar'),
    'CAD': Currency(numericCode: 124, minorUnit: 2, name: 'Canadian dollar'),
    'CDF': Currency(numericCode: 976, minorUnit: 2, name: 'Congolese franc'),
    'CHE': Currency(
        numericCode: 947,
        minorUnit: 2,
        name: 'WIR euro (complementary currency)'),
    'CHF': Currency(numericCode: 756, minorUnit: 2, name: 'Swiss franc'),
    'CHW': Currency(
        numericCode: 948,
        minorUnit: 2,
        name: 'WIR franc (complementary currency)'),
    'CLF': Currency(
        numericCode: 990, minorUnit: 4, name: 'Unidad de Fomento (funds code)'),
    'CLP': Currency(numericCode: 152, minorUnit: 0, name: 'Chilean peso'),
    'CNY': Currency(numericCode: 156, minorUnit: 2, name: 'Chinese yuan[8]'),
    'COP': Currency(numericCode: 170, minorUnit: 2, name: 'Colombian peso'),
    'COU': Currency(
        numericCode: 970,
        minorUnit: 2,
        name: 'Unidad de Valor Real (UVR) (funds code)'),
    'CRC': Currency(numericCode: 188, minorUnit: 2, name: 'Costa Rican colon'),
    'CUC': Currency(
        numericCode: 931, minorUnit: 2, name: 'Cuban convertible peso'),
    'CUP': Currency(numericCode: 192, minorUnit: 2, name: 'Cuban peso'),
    'CVE':
        Currency(numericCode: 132, minorUnit: 2, name: 'Cape Verdean escudo'),
    'CZK': Currency(numericCode: 203, minorUnit: 2, name: 'Czech koruna'),
    'DJF': Currency(numericCode: 262, minorUnit: 0, name: 'Djiboutian franc'),
    'DKK': Currency(numericCode: 208, minorUnit: 2, name: 'Danish krone'),
    'DOP': Currency(numericCode: 214, minorUnit: 2, name: 'Dominican peso'),
    'DZD': Currency(numericCode: 12, minorUnit: 2, name: 'Algerian dinar'),
    'EGP': Currency(numericCode: 818, minorUnit: 2, name: 'Egyptian pound'),
    'ERN': Currency(numericCode: 232, minorUnit: 2, name: 'Eritrean nakfa'),
    'ETB': Currency(numericCode: 230, minorUnit: 2, name: 'Ethiopian birr'),
    'EUR': Currency(numericCode: 978, minorUnit: 2, name: 'Euro'),
    'FJD': Currency(numericCode: 242, minorUnit: 2, name: 'Fiji dollar'),
    'FKP': Currency(
        numericCode: 238, minorUnit: 2, name: 'Falkland Islands pound'),
    'GBP': Currency(numericCode: 826, minorUnit: 2, name: 'Pound sterling'),
    'GEL': Currency(numericCode: 981, minorUnit: 2, name: 'Georgian lari'),
    'GHS': Currency(numericCode: 936, minorUnit: 2, name: 'Ghanaian cedi'),
    'GIP': Currency(numericCode: 292, minorUnit: 2, name: 'Gibraltar pound'),
    'GMD': Currency(numericCode: 270, minorUnit: 2, name: 'Gambian dalasi'),
    'GNF': Currency(numericCode: 324, minorUnit: 0, name: 'Guinean franc'),
    'GTQ': Currency(numericCode: 320, minorUnit: 2, name: 'Guatemalan quetzal'),
    'GYD': Currency(numericCode: 328, minorUnit: 2, name: 'Guyanese dollar'),
    'HKD': Currency(numericCode: 344, minorUnit: 2, name: 'Hong Kong dollar'),
    'HNL': Currency(numericCode: 340, minorUnit: 2, name: 'Honduran lempira'),
    'HRK': Currency(numericCode: 191, minorUnit: 2, name: 'Croatian kuna'),
    'HTG': Currency(numericCode: 332, minorUnit: 2, name: 'Haitian gourde'),
    'HUF': Currency(numericCode: 348, minorUnit: 2, name: 'Hungarian forint'),
    'IDR': Currency(numericCode: 360, minorUnit: 2, name: 'Indonesian rupiah'),
    'ILS': Currency(numericCode: 376, minorUnit: 2, name: 'Israeli new shekel'),
    'INR': Currency(numericCode: 356, minorUnit: 2, name: 'Indian rupee'),
    'IQD': Currency(numericCode: 368, minorUnit: 3, name: 'Iraqi dinar'),
    'IRR': Currency(numericCode: 364, minorUnit: 2, name: 'Iranian rial'),
    'ISK': Currency(numericCode: 352, minorUnit: 0, name: 'Icelandic króna'),
    'JMD': Currency(numericCode: 388, minorUnit: 2, name: 'Jamaican dollar'),
    'JOD': Currency(numericCode: 400, minorUnit: 3, name: 'Jordanian dinar'),
    'JPY': Currency(numericCode: 392, minorUnit: 0, name: 'Japanese yen'),
    'KES': Currency(numericCode: 404, minorUnit: 2, name: 'Kenyan shilling'),
    'KGS': Currency(numericCode: 417, minorUnit: 2, name: 'Kyrgyzstani som'),
    'KHR': Currency(numericCode: 116, minorUnit: 2, name: 'Cambodian riel'),
    'KMF': Currency(numericCode: 174, minorUnit: 0, name: 'Comoro franc'),
    'KPW': Currency(numericCode: 408, minorUnit: 2, name: 'North Korean won'),
    'KRW': Currency(numericCode: 410, minorUnit: 0, name: 'South Korean won'),
    'KWD': Currency(numericCode: 414, minorUnit: 3, name: 'Kuwaiti dinar'),
    'KYD':
        Currency(numericCode: 136, minorUnit: 2, name: 'Cayman Islands dollar'),
    'KZT': Currency(numericCode: 398, minorUnit: 2, name: 'Kazakhstani tenge'),
    'LAK': Currency(numericCode: 418, minorUnit: 2, name: 'Lao kip'),
    'LBP': Currency(numericCode: 422, minorUnit: 2, name: 'Lebanese pound'),
    'LKR': Currency(numericCode: 144, minorUnit: 2, name: 'Sri Lankan rupee'),
    'LRD': Currency(numericCode: 430, minorUnit: 2, name: 'Liberian dollar'),
    'LSL': Currency(numericCode: 426, minorUnit: 2, name: 'Lesotho loti'),
    'LYD': Currency(numericCode: 434, minorUnit: 3, name: 'Libyan dinar'),
    'MAD': Currency(numericCode: 504, minorUnit: 2, name: 'Moroccan dirham'),
    'MDL': Currency(numericCode: 498, minorUnit: 2, name: 'Moldovan leu'),
    'MGA': Currency(numericCode: 969, minorUnit: 2, name: 'Malagasy ariary'),
    'MKD': Currency(numericCode: 807, minorUnit: 2, name: 'Macedonian denar'),
    'MMK': Currency(numericCode: 104, minorUnit: 2, name: 'Myanmar kyat'),
    'MNT': Currency(numericCode: 496, minorUnit: 2, name: 'Mongolian tögrög'),
    'MOP': Currency(numericCode: 446, minorUnit: 2, name: 'Macanese pataca'),
    'MRU':
        Currency(numericCode: 929, minorUnit: 2, name: 'Mauritanian ouguiya'),
    'MUR': Currency(numericCode: 480, minorUnit: 2, name: 'Mauritian rupee'),
    'MVR': Currency(numericCode: 462, minorUnit: 2, name: 'Maldivian rufiyaa'),
    'MWK': Currency(numericCode: 454, minorUnit: 2, name: 'Malawian kwacha'),
    'MXN': Currency(numericCode: 484, minorUnit: 2, name: 'Mexican peso'),
    'MXV': Currency(
        numericCode: 979,
        minorUnit: 2,
        name: 'Mexican Unidad de Inversion (UDI) (funds code)'),
    'MYR': Currency(numericCode: 458, minorUnit: 2, name: 'Malaysian ringgit'),
    'MZN': Currency(numericCode: 943, minorUnit: 2, name: 'Mozambican metical'),
    'NAD': Currency(numericCode: 516, minorUnit: 2, name: 'Namibian dollar'),
    'NGN': Currency(numericCode: 566, minorUnit: 2, name: 'Nigerian naira'),
    'NIO': Currency(numericCode: 558, minorUnit: 2, name: 'Nicaraguan córdoba'),
    'NOK': Currency(numericCode: 578, minorUnit: 2, name: 'Norwegian krone'),
    'NPR': Currency(numericCode: 524, minorUnit: 2, name: 'Nepalese rupee'),
    'NZD': Currency(numericCode: 554, minorUnit: 2, name: 'New Zealand dollar'),
    'OMR': Currency(numericCode: 512, minorUnit: 3, name: 'Omani rial'),
    'PAB': Currency(numericCode: 590, minorUnit: 2, name: 'Panamanian balboa'),
    'PEN': Currency(numericCode: 604, minorUnit: 2, name: 'Peruvian sol'),
    'PGK': Currency(
        numericCode: 598, minorUnit: 2, name: 'Papua New Guinean kina'),
    'PHP': Currency(numericCode: 608, minorUnit: 2, name: 'Philippine peso'),
    'PKR': Currency(numericCode: 586, minorUnit: 2, name: 'Pakistani rupee'),
    'PLN': Currency(numericCode: 985, minorUnit: 2, name: 'Polish złoty'),
    'PYG': Currency(numericCode: 600, minorUnit: 0, name: 'Paraguayan guaraní'),
    'QAR': Currency(numericCode: 634, minorUnit: 2, name: 'Qatari riyal'),
    'RON': Currency(numericCode: 946, minorUnit: 2, name: 'Romanian leu'),
    'RSD': Currency(numericCode: 941, minorUnit: 2, name: 'Serbian dinar'),
    'RUB': Currency(numericCode: 643, minorUnit: 2, name: 'Russian ruble'),
    'RWF': Currency(numericCode: 646, minorUnit: 0, name: 'Rwandan franc'),
    'SAR': Currency(numericCode: 682, minorUnit: 2, name: 'Saudi riyal'),
    'SBD':
        Currency(numericCode: 90, minorUnit: 2, name: 'Solomon Islands dollar'),
    'SCR': Currency(numericCode: 690, minorUnit: 2, name: 'Seychelles rupee'),
    'SDG': Currency(numericCode: 938, minorUnit: 2, name: 'Sudanese pound'),
    'SEK': Currency(numericCode: 752, minorUnit: 2, name: 'Swedish krona'),
    'SGD': Currency(numericCode: 702, minorUnit: 2, name: 'Singapore dollar'),
    'SHP': Currency(numericCode: 654, minorUnit: 2, name: 'Saint Helena pound'),
    'SLL':
        Currency(numericCode: 694, minorUnit: 2, name: 'Sierra Leonean leone'),
    'SOS': Currency(numericCode: 706, minorUnit: 2, name: 'Somali shilling'),
    'SRD': Currency(numericCode: 968, minorUnit: 2, name: 'Surinamese dollar'),
    'SSP':
        Currency(numericCode: 728, minorUnit: 2, name: 'South Sudanese pound'),
    'STN': Currency(
        numericCode: 930, minorUnit: 2, name: 'São Tomé and Príncipe dobra'),
    'SVC': Currency(numericCode: 222, minorUnit: 2, name: 'Salvadoran colón'),
    'SYP': Currency(numericCode: 760, minorUnit: 2, name: 'Syrian pound'),
    'SZL': Currency(numericCode: 748, minorUnit: 2, name: 'Swazi lilangeni'),
    'THB': Currency(numericCode: 764, minorUnit: 2, name: 'Thai baht'),
    'TJS': Currency(numericCode: 972, minorUnit: 2, name: 'Tajikistani somoni'),
    'TMT': Currency(numericCode: 934, minorUnit: 2, name: 'Turkmenistan manat'),
    'TND': Currency(numericCode: 788, minorUnit: 3, name: 'Tunisian dinar'),
    'TOP': Currency(numericCode: 776, minorUnit: 2, name: 'Tongan paʻanga'),
    'TRY': Currency(numericCode: 949, minorUnit: 2, name: 'Turkish lira'),
    'TTD': Currency(
        numericCode: 780, minorUnit: 2, name: 'Trinidad and Tobago dollar'),
    'TWD': Currency(numericCode: 901, minorUnit: 2, name: 'New Taiwan dollar'),
    'TZS': Currency(numericCode: 834, minorUnit: 2, name: 'Tanzanian shilling'),
    'UAH': Currency(numericCode: 980, minorUnit: 2, name: 'Ukrainian hryvnia'),
    'UGX': Currency(numericCode: 800, minorUnit: 0, name: 'Ugandan shilling'),
    'USD':
        Currency(numericCode: 840, minorUnit: 2, name: 'United States dollar'),
    'USN': Currency(
        numericCode: 997,
        minorUnit: 2,
        name: 'United States dollar (next day) (funds code)'),
    'UYI': Currency(
        numericCode: 940,
        minorUnit: 0,
        name: 'Uruguay Peso en Unidades Indexadas (URUIURUI) (funds code)'),
    'UYU': Currency(numericCode: 858, minorUnit: 2, name: 'Uruguayan peso'),
    'UYW': Currency(numericCode: 927, minorUnit: 4, name: 'Unidad previsional'),
    'UZS': Currency(numericCode: 860, minorUnit: 2, name: 'Uzbekistan som'),
    'VED': Currency(
        numericCode: 926, minorUnit: 2, name: 'Venezuelan bolívar digital'),
    'VES': Currency(
        numericCode: 928, minorUnit: 2, name: 'Venezuelan bolívar soberano'),
    'VND': Currency(numericCode: 704, minorUnit: 0, name: 'Vietnamese đồng'),
    'VUV': Currency(numericCode: 548, minorUnit: 0, name: 'Vanuatu vatu'),
    'WST': Currency(numericCode: 882, minorUnit: 2, name: 'Samoan tala'),
    'XAF': Currency(numericCode: 950, minorUnit: 0, name: 'CFA franc BEAC'),
    'XAG': Currency(
        numericCode: 961, minorUnit: null, name: 'Silver (one troy ounce)'),
    'XAU': Currency(
        numericCode: 959, minorUnit: null, name: 'Gold (one troy ounce)'),
    'XBA': Currency(
        numericCode: 955,
        minorUnit: null,
        name: 'European Composite Unit (EURCO) (bond market unit)'),
    'XBB': Currency(
        numericCode: 956,
        minorUnit: null,
        name: 'European Monetary Unit (E.M.U.-6) (bond market unit)'),
    'XBC': Currency(
        numericCode: 957,
        minorUnit: null,
        name: 'European Unit of Account 9 (E.U.A.-9) (bond market unit)'),
    'XBD': Currency(
        numericCode: 958,
        minorUnit: null,
        name: 'European Unit of Account 17 (E.U.A.-17) (bond market unit)'),
    'XCD':
        Currency(numericCode: 951, minorUnit: 2, name: 'East Caribbean dollar'),
    'XDR': Currency(
        numericCode: 960, minorUnit: null, name: 'Special drawing rights'),
    'XOF': Currency(numericCode: 952, minorUnit: 0, name: 'CFA franc BCEAO'),
    'XPD': Currency(
        numericCode: 964, minorUnit: null, name: 'Palladium (one troy ounce)'),
    'XPF': Currency(
        numericCode: 953, minorUnit: 0, name: 'CFP franc (franc Pacifique)'),
    'XPT': Currency(
        numericCode: 962, minorUnit: null, name: 'Platinum (one troy ounce)'),
    'XSU': Currency(numericCode: 994, minorUnit: null, name: 'SUCRE'),
    'XTS': Currency(
        numericCode: 963, minorUnit: null, name: 'Code reserved for testing'),
    'XUA': Currency(
        numericCode: 965, minorUnit: null, name: 'ADB Unit of Account'),
    'XXX': Currency(numericCode: 999, minorUnit: null, name: 'No currency'),
    'YER': Currency(numericCode: 886, minorUnit: 2, name: 'Yemeni rial'),
    'ZAR': Currency(numericCode: 710, minorUnit: 2, name: 'South African rand'),
    'ZMW': Currency(numericCode: 967, minorUnit: 2, name: 'Zambian kwacha'),
    'ZWL': Currency(numericCode: 932, minorUnit: 2, name: 'Zimbabwean dollar')
  };
}
