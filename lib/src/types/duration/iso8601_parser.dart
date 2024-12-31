// Shamelessly ported from https://github.com/rails/rails/tree/main/activesupport
//
// Copyright (c) 2005-2021 David Heinemeier Hansson

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import 'package:string_scanner/string_scanner.dart';

enum _DurationParsingMode {
  start,
  sign,
  date,
  time,
}

/// Parses a string formatted according to ISO 8601 Duration into the hash.
///
/// See {ISO 8601}[https://en.wikipedia.org/wiki/ISO_8601#Durations] for more information.
///
/// This parser allows negative parts to be present in pattern.
class ISO8601DurationParser {
  static final _periodOrComma = RegExp('\\.|,');
  static const _period = '.';
  static const _comma = ',';

  static final _signMarker = RegExp('^-|\\+|');
  static final _dateMarker = RegExp('P');
  static final _timeMarker = RegExp('T');
  static final _dateComponent = RegExp('(-?\\d+(?:[.,]\\d+)?)(Y|M|D|W)');
  static final _timeComponent = RegExp('(-?\\d+(?:[.,]\\d+)?)(H|M|S)');

  static const _dateToPart = {
    'Y': 'years',
    'M': 'months',
    'W': 'weeks',
    'D': 'days'
  };
  static const _timeToPart = {'H': 'hours', 'M': 'minutes', 'S': 'seconds'};

  static const _dateComponents = ['years', 'months', 'days'];
  static const _timeComponents = ['hours', 'minutes', 'seconds'];

  final Map<String, num> _parts;
  final StringScanner _scanner;
  _DurationParsingMode _mode;
  int _sign;

  /// Construct a new parser to parse the given string
  ISO8601DurationParser(String string)
      : _scanner = StringScanner(string),
        _parts = {},
        _mode = _DurationParsingMode.start,
        _sign = 1;

  /// Parse the string into a map of duration parts
  Map<String, num> parse() {
    while (!_isFinished()) {
      switch (_mode) {
        case _DurationParsingMode.start:
          if (_scan(_signMarker)) {
            _sign = _scanner.lastMatch![0] == '-' ? -1 : 1;
            _mode = _DurationParsingMode.sign;
          } else {
            _raiseParsingError();
          }
          break;
        case _DurationParsingMode.sign:
          if (_scan(_dateMarker)) {
            _mode = _DurationParsingMode.date;
          } else {
            _raiseParsingError();
          }
          break;
        case _DurationParsingMode.date:
          if (_scan(_timeMarker)) {
            _mode = _DurationParsingMode.time;
          } else if (_scan(_dateComponent)) {
            _parts[_dateToPart[_scanner.lastMatch![2]!]!] = _number() * _sign;
          } else {
            _raiseParsingError();
          }
          break;
        case _DurationParsingMode.time:
          if (_scan(_timeComponent)) {
            _parts[_timeToPart[_scanner.lastMatch![2]!]!] = _number() * _sign;
          } else {
            _raiseParsingError();
          }
          break;
      }
    }

    _validate();
    return _parts;
  }

  bool _isFinished() {
    return _scanner.rest.isEmpty;
  }

  // Parses number which can be a float with either comma or period.
  num _number() {
    return (_periodOrComma.hasMatch(_scanner.lastMatch![1]!))
        ? double.parse(_scanner.lastMatch![1]!.replaceAll(_comma, _period))
        : int.parse(_scanner.lastMatch![1]!);
  }

  bool _scan(pattern) {
    return _scanner.scan(pattern);
  }

  void _raiseParsingError([String? reason]) {
    throw "Invalid ISO 8601 duration: ${_scanner.string} $reason".trim();
  }

  // Checks for various semantic errors as stated in ISO 8601 standard.
  bool _validate() {
    if (_parts.isEmpty) _raiseParsingError('is empty duration');

    // Mixing any of Y, M, D with W is invalid.
    if (_parts.containsKey('weeks') &&
        _dateComponents.any((e) => _parts.containsKey(e))) {
      _raiseParsingError('mixing weeks with other date parts not allowed');
    }

    // Specifying an empty T part is invalid.
    if (_mode == _DurationParsingMode.time &&
        !_timeComponents.any((e) => _parts.containsKey(e))) {
      _raiseParsingError('time part marker is present but time part is empty');
    }

    var fractions =
        _parts.values.where((a) => a != 0).where((a) => (a % 1) != 0);
    if (fractions.isNotEmpty &&
        !(fractions.length == 1 &&
            fractions.last == _parts.values.where((a) => a != 0).last)) {
      _raiseParsingError('(only last part can be fractional)');
    }

    return true;
  }
}
