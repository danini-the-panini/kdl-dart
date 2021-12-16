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
  Start,
  Sign,
  Date,
  Time,
}

// Parses a string formatted according to ISO 8601 Duration into the hash.
//
// See {ISO 8601}[https://en.wikipedia.org/wiki/ISO_8601#Durations] for more information.
//
// This parser allows negative parts to be present in pattern.
class ISO8601DurationParser {
  static final PERIOD_OR_COMMA = RegExp('\.|,/');
  static const PERIOD = '.';
  static const COMMA = ',';

  static final SIGN_MARKER = RegExp('\\A-|\\+|');
  static final DATE_MARKER = RegExp('P');
  static final TIME_MARKER = RegExp('T');
  static final DATE_COMPONENT = RegExp('(-?\\d+(?:[.,]\\d+)?)(Y|M|D|W)');
  static final TIME_COMPONENT = RegExp('(-?\\d+(?:[.,]\\d+)?)(H|M|S)');

  static const DATE_TO_PART = { 'Y': 'years', 'M': 'months', 'W': 'weeks', 'D': 'days' };
  static const TIME_TO_PART = { 'H': 'hours', 'M': 'minutes', 'S': 'seconds' };

  static const DATE_COMPONENTS = ['years', 'months', 'days'];
  static const TIME_COMPONENTS = ['hours', 'minutes', 'seconds'];

  Map<String, num> parts;
  StringScanner scanner;
  DurationParsingMode mode;
  int sign;

  ISO8601DurationParser(String string) :
    scanner = StringScanner(string),
    parts = {},
    mode = DurationParsingMode.Start,
    sign = 1;

  parse() {
    while (!_isFinished()) {
      switch(mode) {
      case DurationParsingMode.Start:
        if (_scan(SIGN_MARKER)) {
          sign = scanner.lastMatch![0] == '-' ? -1 : 1;
          mode = DurationParsingMode.Sign;
        } else {
          _raiseParsingError();
        }
        break;
      case DurationParsingMode.Sign:
        if (_scan(DATE_MARKER)) {
          mode = DurationParsingMode.Date;
        } else {
          _raiseParsingError();
        }
        break;
      case DurationParsingMode.Date:
        if (_scan(TIME_MARKER)) {
          mode = DurationParsingMode.Time;
        } else if (_scan(DATE_COMPONENT)) {
          parts[DATE_TO_PART[scanner.lastMatch![2]!]!] = _number() * sign;
        } else {
          _raiseParsingError();
        }
        break;
      case DurationParsingMode.Time:
        if (_scan(TIME_COMPONENT)) {
          parts[TIME_TO_PART[scanner.lastMatch![2]!]!] = _number() * sign;
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
    return scanner.rest.length == 0;
  }

  // Parses number which can be a float with either comma or period.
  num _number() {
    return (PERIOD_OR_COMMA.hasMatch(scanner.lastMatch![1]!)) ?
      double.parse(scanner.lastMatch![1]!.replaceAll(COMMA, PERIOD)) :
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
    if (parts.containsKey('weeks') && DATE_COMPONENTS.any((e) => parts.containsKey(e))) {
      _raiseParsingError('mixing weeks with other date parts not allowed');
    }

    // Specifying an empty T part is invalid.
    if (mode == DurationParsingMode.Time && !TIME_COMPONENTS.any((e) => parts.containsKey(e))) {
      _raiseParsingError('time part marker is present but time part is empty');
    }

    var fractions = parts.values.where((a) => a != 0).where((a) => (a % 1) != 0);
    if (!fractions.isEmpty && !(fractions.length == 1 && fractions.last == parts.values.where((a) => a != 0).last)) {
      _raiseParsingError('(only last part can be fractional)');
    }

    return true;
  }
}
