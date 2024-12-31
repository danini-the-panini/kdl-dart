// IPv4 and IPv6 Regular Expression patterns copied from Ruby's lib/resolv.rb
//
// Copyright (C) 1993-2013 Yukihiro Matsumoto. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.

import "package:kdl/src/document.dart";
import "package:kdl/src/exception.dart";

class KdlIP extends KdlValue<String> {
  KdlIP(super.value, [super.type]);
}

class KdlIPV4 extends KdlIP {
  static final decbyte = r"""
    0
    |1(?:[0-9][0-9]?)?
    |2(?:[0-4][0-9]?|5[0-5]?|[6-9])?
    |[3-9][0-9]?
  """
      .trim()
      .split('\n')
      .map((v) => v.trim())
      .join();
  static final regexp =
      RegExp("^($decbyte)\\.($decbyte)\\.($decbyte)\\.($decbyte)\$");

  KdlIPV4(super.value, [super.type]);

  static call(KdlValue value, [String type = 'ipv4']) {
    if (value is! KdlString) return null;
    var addr = value.value;

    if (!regexp.hasMatch(addr)) {
      throw KdlException("invalid ipv4 address: $addr");
    }

    return KdlIPV4(addr, type);
  }
}

class KdlIPV6 extends KdlIP {
  // IPv6 address format a:b:c:d:e:f:g:h
  static final regexp8Hex = r"""
    (?:[0-9A-Fa-f]{1,4}:){7}
      [0-9A-Fa-f]{1,4}
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // Compressed IPv6 address format a::b
  static final regexpCompressedHex = r"""
    ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::
    ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // IPv4 mapped IPv6 address format a:b:c:d:e:f:w.x.y.z
  static final regexp6Hex4Dec = r"""
    ((?:[0-9A-Fa-f]{1,4}:){6,6})
    (\d+)\.(\d+)\.(\d+)\.(\d+)
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // Compressed IPv4 mapped IPv6 address format a::b:w.x.y.z
  static final _regexpCompressedHex4Dec = r"""
    ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::
    ((?:[0-9A-Fa-f]{1,4}:)*)
    (\d+)\.(\d+)\.(\d+)\.(\d+)
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // IPv6 link local address format fe80:b:c:d:e:f:g:h%em1
  static final regexp8HexLinkLocal = r"""
    [Ff][Ee]80
    (?::[0-9A-Fa-f]{1,4}){7}
    %[-0-9A-Za-z._~]+
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // Compressed IPv6 link local address format fe80::b%em1
  static final regexpCompressedHexLinkLocal = r"""
    [Ff][Ee]80:
    (?:
      ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::
      ((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)
      |
      :((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)
    )?
    :[0-9A-Fa-f]{1,4}%[-0-9A-Za-z._~]+
  """
      .split('\n')
      .map((v) => v.trim())
      .join();

  // A composite IPv6 address Regexp.
  static final regexp = RegExp("^${[
    regexp8Hex,
    regexpCompressedHex,
    regexp6Hex4Dec,
    _regexpCompressedHex4Dec,
    regexp8HexLinkLocal,
    regexpCompressedHexLinkLocal
  ].map((v) => "(?:$v)").join('|')}\$");

  KdlIPV6(super.value, [super.type]);

  static call(KdlValue value, [String type = 'ipv6']) {
    if (value is! KdlString) return null;
    var addr = value.value;

    if (!regexp.hasMatch(addr)) {
      throw KdlException("invalid ipv6 address: $addr");
    }

    return KdlIPV6(addr, type);
  }
}
