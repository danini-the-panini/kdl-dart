// Source: https://github.com/Ephenodrom/Dart-Basic-Utils/blob/master/lib/src/library/IDNAConverter.dart
//
// MIT License
// Copyright (c) 2021 Ephenodrom
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

///
/// Implementation of IDNA - RFC 3490 standard converter according to <http://www.rfc-base.org/rfc-3490.html>
///
class IDNAConverter {
  static const _invalidInput = 'Invalid input';
  static const _overflow = 'Overflow: input needs wider integers to process';
  static const _notBasic = 'Illegal input >= 0x80 (not a basic code point)';

  static const int _base = 36;
  static const int _tMin = 1;
  static const int _tMax = 26;

  static const int _skew = 38;
  static const int _damp = 700;

  static const int _initialBias = 72;
  static const int _initialN = 128; // 0x80
  static const _delimiter = '-'; // '\x2D'

  /// Highest positive signed 32-bit float value
  static const _maxInt = 2147483647; // aka. 0x7FFFFFFF or 2^31-1

  static final RegExp _regexPunycode = RegExp(r'^xn--');
  static final RegExp _regexNonASCII = RegExp(r'[^\0-\x7E]'); // non-ASCII chars
  static final RegExp _regexSeparators =
      RegExp(r'[\u002E\u3002\uFF0E\uFF61]'); // RFC 3490 separators
  static final RegExp _regexUrlprefix = RegExp(r'^http://|^https://');

  ///
  /// Converts a string that contains unicode symbols to a string with only ASCII symbols.
  ///
  static String encode(String input) {
    var n = _initialN;
    var delta = 0;
    var bias = _initialBias;
    var output = <int>[];

    // Copy all basic code points to the output
    var b = 0;
    for (var i = 0; i < input.length; i++) {
      var c = input.codeUnitAt(i);
      if (isBasic(c)) {
        output.add(c);
        b++;
      }
    }

    // Append delimiter
    if (b > 0) {
      output.add(_delimiter.codeUnitAt(0));
    }

    var h = b;
    while (h < input.length) {
      var m = _maxInt;

      // Find the minimum code point >= n
      for (var i = 0; i < input.length; i++) {
        var c = input.codeUnitAt(i);
        if (c >= n && c < m) {
          m = c;
        }
      }

      if (m - n > (_maxInt - delta) / (h + 1)) {
        throw ArgumentError(_overflow);
      }
      delta = delta + (m - n) * (h + 1);
      n = m;

      for (var j = 0; j < input.length; j++) {
        var c = input.codeUnitAt(j);
        if (c < n) {
          delta++;
          if (0 == delta) {
            throw ArgumentError(_overflow);
          }
        }
        if (c == n) {
          var q = delta;

          for (var k = _base;; k += _base) {
            int t;
            if (k <= bias) {
              t = _tMin;
            } else if (k >= bias + _tMax) {
              t = _tMax;
            } else {
              t = k - bias;
            }
            if (q < t) {
              break;
            }
            output.add((digitToBasic(t + (q - t) % (_base - t))));
            q = ((q - t) / (_base - t)).floor();
          }

          output.add(digitToBasic(q));
          bias = _adapt(delta, h + 1, h == b);
          delta = 0;
          h++;
        }
      }

      delta++;
      n++;
    }

    return String.fromCharCodes(output);
  }

  ///
  /// Decode a ASCII string to the corresponding unicode string.
  ///
  static String decode(String input) {
    var n = _initialN;
    var i = 0;
    var bias = _initialBias;
    var output = <int>[];

    var d = input.lastIndexOf(_delimiter);
    if (d > 0) {
      for (var j = 0; j < d; j++) {
        var c = input.codeUnitAt(j);
        if (!isBasic(c)) {
          throw ArgumentError(_invalidInput);
        }
        output.add(c);
      }
      d++;
    } else {
      d = 0;
    }

    while (d < input.length) {
      var oldi = i;
      var w = 1;

      for (var k = _base;; k += _base) {
        if (d == input.length) {
          throw ArgumentError(_invalidInput);
        }
        var c = input.codeUnitAt(d++);
        var digit = basicToDigit(c);
        if (digit > (_maxInt - i) / w) {
          throw ArgumentError(_overflow);
        }

        i = i + digit * w;

        int t;
        if (k <= bias) {
          t = _tMin;
        } else if (k >= bias + _tMax) {
          t = _tMax;
        } else {
          t = k - bias;
        }
        if (digit < t) {
          break;
        }
        w = w * (_base - t);
      }

      bias = _adapt(i - oldi, output.length + 1, oldi == 0);

      if (i / (output.length + 1) > _maxInt - n) {
        throw ArgumentError(_overflow);
      }

      n = (n + i / (output.length + 1)).floor();
      i = i % (output.length + 1);
      output.insert(i, n);
      i++;
    }

    return String.fromCharCodes(output);
  }

  static int _adapt(int delta, int numpoints, bool first) {
    if (first) {
      delta = (delta / _damp).floor();
    } else {
      delta = (delta / 2).floor();
    }

    delta = delta + (delta / numpoints).floor();

    var k = 0;
    while (delta > ((_base - _tMin) * _tMax) / 2) {
      delta = (delta / (_base - _tMin)).floor();
      k = k + _base;
    }

    return (k + ((_base - _tMin + 1) * delta) / (delta + _skew)).floor();
  }

  ///
  /// Checks if the given [value] is within the ASCII set
  ///
  static bool isBasic(int value) {
    return value < 0x80;
  }

  /// Converts a digit/integer into a basic code point.
  /// @see `basicToDigit()`
  /// @private
  /// @param {Number} digit The numeric value of a basic code point.
  /// @returns {Number} The basic code point whose value
  static int digitToBasic(int digit) {
    if (digit < 26) {
      // 0..25 : 'a'..'z'
      return digit + 'a'.codeUnitAt(0);
    } else if (digit < 36) {
      // 26..35 : '0'..'9';
      return digit - 26 + '0'.codeUnitAt(0);
    } else {
      throw ArgumentError(_invalidInput);
    }
  }

  /// Converts a basic code point into a digit/integer.
  /// @see `digitToBasic()`
  /// @private
  /// @param {Number} codePoint The basic numeric code point value.
  /// @returns {Number} The numeric value of a basic code point (for use in
  /// representing integers) in the range `0` to `base - 1`, or `base` if
  /// the code point does not represent a value.
  static int basicToDigit(int codePoint) {
    if (codePoint - '0'.codeUnitAt(0) < 10) {
      // '0'..'9' : 26..35
      return codePoint - '0'.codeUnitAt(0) + 26;
    } else if (codePoint - 'a'.codeUnitAt(0) < 26) {
      // 'a'..'z' : 0..25
      return codePoint - 'a'.codeUnitAt(0);
    } else {
      throw ArgumentError(_invalidInput);
    }
  }

  ///
  /// Converts a domain name or url that contains unicode symbols to a string with only ASCII symbols.
  ///
  static String urlDecode(String value) {
    return _urlConvert(value, false);
  }

  ///
  /// Decode a ASCII domain name or url to the corresponding unicode string.
  ///
  static String urlEncode(String value) {
    return _urlConvert(value, true);
  }

  static String _urlConvert(String url, bool shouldencode) {
    var url0 = <String>[];
    var result = <String>[];
    if (_regexUrlprefix.hasMatch(url)) {
      url0 = url.split('/');
    } else {
      url0.add(url);
    }
    for (var suburl in url0) {
      suburl = suburl.replaceAll(_regexSeparators, '\x2E');

      var split = suburl.split('.');

      var join = <String>[];

      for (var elem in split) {
        // do decode and encode
        if (shouldencode) {
          if (_regexPunycode.hasMatch(elem) ||
              _regexNonASCII.hasMatch(elem) == false) {
            join.add(elem);
          } else {
            join.add('xn--${encode(elem)}');
          }
        } else {
          if (_regexNonASCII.hasMatch(elem)) {
            throw ArgumentError(_notBasic);
          } else {
            join.add(_regexPunycode.hasMatch(elem)
                ? decode(elem.replaceFirst(_regexPunycode, ''))
                : elem);
          }
        }
      }
      result.add(join.isNotEmpty ? join.join('.') : suburl);
    }

    return result.length > 1 ? result.join('/') : result.elementAt(0);
  }
}
