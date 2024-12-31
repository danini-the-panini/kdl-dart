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

enum DurationParsingMode {
  start,
  sign,
  date,
  time,
}

// Parses a string formatted according to ISO 8601 Duration into the hash.
//
// See {ISO 8601}[https://en.wikipedia.org/wiki/ISO_8601#Durations] for more information.
//
// This parser allows negative parts to be present in pattern.
class ISO8601DurationParser {
  static final periodOrComma = RegExp('\\.|,');
  static const period = '.';
  static const comma = ',';

  static final signMarker = RegExp('^-|\\+|');
  static final dateMarker = RegExp('P');
  static final timeMarker = RegExp('T');
  static final dateComponent = RegExp('(-?\\d+(?:[.,]\\d+)?)(Y|M|D|W)');
  static final timeComponent = RegExp('(-?\\d+(?:[.,]\\d+)?)(H|M|S)');

  static const dateToPart = { 'Y': 'years', 'M': 'months', 'W': 'weeks', 'D': 'days' };
  static const timeToPart = { 'H': 'hours', 'M': 'minutes', 'S': 'seconds' };

  static const dateComponents = ['years', 'months', 'days'];
  static const timeComponents = ['hours', 'minutes', 'seconds'];

  Map<String, num> parts;
  StringScanner scanner;
  DurationParsingMode mode;
  int sign;

  ISO8601DurationParser(String string) :
    scanner = StringScanner(string),
    parts = {},
    mode = DurationParsingMode.start,
    sign = 1;

  parse() {
    while (!_isFinished()) {
      switch(mode) {
      case DurationParsingMode.start:
        if (_scan(signMarker)) {
          sign = scanner.lastMatch![0] == '-' ? -1 : 1;
          mode = DurationParsingMode.sign;
        } else {
          _raiseParsingError();
        }
        break;
      case DurationParsingMode.sign:
        if (_scan(dateMarker)) {
          mode = DurationParsingMode.date;
        } else {
          _raiseParsingError();
        }
        break;
      case DurationParsingMode.date:
        if (_scan(timeMarker)) {
          mode = DurationParsingMode.time;
        } else if (_scan(dateComponent)) {
          parts[dateToPart[scanner.lastMatch![2]!]!] = _number() * sign;
        } else {
          _raiseParsingError();
        }
        break;
      case DurationParsingMode.time:
        if (_scan(timeComponent)) {
          parts[timeToPart[scanner.lastMatch![2]!]!] = _number() * sign;
        } else {
          _raiseParsingError();
        }
        break;
      }
    }

    _validate();
    return parts;
  }

  bool _isFinished() {
    return scanner.rest.isEmpty;
  }

  // Parses number which can be a float with either comma or period.
  num _number() {
    return (periodOrComma.hasMatch(scanner.lastMatch![1]!)) ?
      double.parse(scanner.lastMatch![1]!.replaceAll(comma, period)) :
      int.parse(scanner.lastMatch![1]!);
  }

  bool _scan(pattern) {
    return scanner.scan(pattern);
  }

  void _raiseParsingError([String? reason]) {
    throw "Invalid ISO 8601 duration: ${scanner.string} $reason".trim();
  }

  // Checks for various semantic errors as stated in ISO 8601 standard.
  bool _validate() {
    if (parts.isEmpty) _raiseParsingError('is empty duration');

    // Mixing any of Y, M, D with W is invalid.
    if (parts.containsKey('weeks') && dateComponents.any((e) => parts.containsKey(e))) {
      _raiseParsingError('mixing weeks with other date parts not allowed');
    }

    // Specifying an empty T part is invalid.
    if (mode == DurationParsingMode.time && !timeComponents.any((e) => parts.containsKey(e))) {
      _raiseParsingError('time part marker is present but time part is empty');
    }

    var fractions = parts.values.where((a) => a != 0).where((a) => (a % 1) != 0);
    if (fractions.isNotEmpty && !(fractions.length == 1 && fractions.last == parts.values.where((a) => a != 0).last)) {
      _raiseParsingError('(only last part can be fractional)');
    }

    return true;
  }
}
