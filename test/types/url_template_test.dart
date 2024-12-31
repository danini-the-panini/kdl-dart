import 'package:test/test.dart';

import 'package:kdl/src/document.dart';
import 'package:kdl/src/types/url_template.dart';

var variables = {
  'count': ['one', 'two', 'three'],
  'dom': ['example', 'com'],
  'dub': 'me/too',
  'hello': 'Hello World!',
  'half': '50%',
  'var': 'value',
  'who': 'fred',
  'base': 'http://example.com/home/',
  'path': '/foo/bar',
  'list': ['red', 'green', 'blue'],
  'keys': { 'semi': ';', 'dot': '.', 'comma': ',' },
  'v': '6',
  'x': '1024',
  'y': '768',
  'empty': '',
  'empty_keys': {},
  'undef': null,
};

void assertExpansionEqual(String template, String expected) {
  var value = KdlURLTemplate.call(KdlString(template))!;
  expect(value.expand(variables), equals(Uri.parse(expected)));
}

void main() {
  test('no variables', () {
    var value = KdlURLTemplate.call(KdlString('https://www.example.com/foo/bar'))!;
    expect(value.expand({}), equals(Uri.parse('https://www.example.com/foo/bar')));
  });

  test('one variable', () {
    var value = KdlURLTemplate.call(KdlString('https://www.example.com/{foo}/bar'))!;
    expect(value.expand({ 'foo': 'lorem' }), equals(Uri.parse('https://www.example.com/lorem/bar')));
  });

  test('multiple_variables', () {
    var value = KdlURLTemplate.call(KdlString('https://www.example.com/{foo}/{bar}'))!;
    expect(value.expand({ 'foo': 'lorem', 'bar': 'ipsum' }),
      equals(Uri.parse('https://www.example.com/lorem/ipsum')));
  });

  test('list expansion', () {
    assertExpansionEqual('{count}', 'one,two,three');
    assertExpansionEqual('{count*}', 'one,two,three');
    assertExpansionEqual('{/count}', '/one,two,three');
    assertExpansionEqual('{/count*}', '/one/two/three');
    assertExpansionEqual('{;count}', ';count=one,two,three');
    assertExpansionEqual('{;count*}', ';count=one;count=two;count=three');
    assertExpansionEqual('{?count}', '?count=one,two,three');
    assertExpansionEqual('{?count*}', '?count=one&count=two&count=three');
    assertExpansionEqual('{&count*}', '&count=one&count=two&count=three');
  });

  test('simple string', () {
    assertExpansionEqual('{var}', 'value');
    assertExpansionEqual('{hello}', 'Hello%20World%21');
    assertExpansionEqual('{half}', '50%25');
    assertExpansionEqual('O{empty}X', 'OX');
    assertExpansionEqual('O{undef}X', 'OX');
    assertExpansionEqual('{x,y}', '1024,768');
    assertExpansionEqual('{x,hello,y}', '1024,Hello%20World%21,768');
    assertExpansionEqual('?{x,empty}', '?1024,');
    assertExpansionEqual('?{x,undef}', '?1024');
    assertExpansionEqual('?{undef,y}', '?768');
    assertExpansionEqual('{var:3}', 'val');
    assertExpansionEqual('{var:30}', 'value');
    assertExpansionEqual('{list}', 'red,green,blue');
    assertExpansionEqual('{list*}', 'red,green,blue');
    assertExpansionEqual('{keys}', 'semi,%3B,dot,.,comma,%2C');
    assertExpansionEqual('{keys*}', 'semi=%3B,dot=.,comma=%2C');
  });

  test('reserved expansion', () {
    assertExpansionEqual('{+var}', 'value');
    assertExpansionEqual('{+hello}', 'Hello%20World!');
    assertExpansionEqual('{+half}', '50%25');

    assertExpansionEqual('{base}index', 'http%3A%2F%2Fexample.com%2Fhome%2Findex');
    assertExpansionEqual('{+base}index', 'http://example.com/home/index');
    assertExpansionEqual('O{+empty}X', 'OX');
    assertExpansionEqual('O{+undef}X', 'OX');

    assertExpansionEqual('{+path}/here', '/foo/bar/here');
    assertExpansionEqual('here?ref={+path}', 'here?ref=/foo/bar');
    assertExpansionEqual('up{+path}{var}/here', 'up/foo/barvalue/here');
    assertExpansionEqual('{+x,hello,y}', '1024,Hello%20World!,768');
    assertExpansionEqual('{+path,x}/here', '/foo/bar,1024/here');

    assertExpansionEqual('{+path:6}/here', '/foo/b/here');
    assertExpansionEqual('{+list}', 'red,green,blue');
    assertExpansionEqual('{+list*}', 'red,green,blue');
    assertExpansionEqual('{+keys}', 'semi,;,dot,.,comma,,');
    assertExpansionEqual('{+keys*}', 'semi=;,dot=.,comma=,');
  });

  test('fragment expansion', () {
    assertExpansionEqual('{#var}', '#value');
    assertExpansionEqual('{#hello}', '#Hello%20World!');
    assertExpansionEqual('{#half}', '#50%25');
    assertExpansionEqual('foo{#empty}', 'foo#');
    assertExpansionEqual('foo{#undef}', 'foo');
    assertExpansionEqual('{#x,hello,y}', '#1024,Hello%20World!,768');
    assertExpansionEqual('{#path,x}/here', '#/foo/bar,1024/here');
    assertExpansionEqual('{#path:6}/here', '#/foo/b/here');
    assertExpansionEqual('{#list}', '#red,green,blue');
    assertExpansionEqual('{#list*}', '#red,green,blue');
    assertExpansionEqual('{#keys}', '#semi,;,dot,.,comma,,');
    assertExpansionEqual('{#keys*}', '#semi=;,dot=.,comma=,');
  });

  test('label expansion', () {
    assertExpansionEqual('{.who}', '.fred');
    assertExpansionEqual('{.who,who}', '.fred.fred');
    assertExpansionEqual('{.half,who}', '.50%25.fred');
    assertExpansionEqual('www{.dom*}', 'www.example.com');
    assertExpansionEqual('X{.var}', 'X.value');
    assertExpansionEqual('X{.empty}', 'X.');
    assertExpansionEqual('X{.undef}', 'X');
    assertExpansionEqual('X{.var:3}', 'X.val');
    assertExpansionEqual('X{.list}', 'X.red,green,blue');
    assertExpansionEqual('X{.list*}', 'X.red.green.blue');
    assertExpansionEqual('X{.keys}', 'X.semi,%3B,dot,.,comma,%2C');
    assertExpansionEqual('X{.keys*}', 'X.semi=%3B.dot=..comma=%2C');
    assertExpansionEqual('X{.empty_keys}', 'X');
    assertExpansionEqual('X{.empty_keys*}', 'X');
  });

  test('path expansion', () {
    assertExpansionEqual('{/who}', '/fred');
    assertExpansionEqual('{/who,who}', '/fred/fred');
    assertExpansionEqual('{/half,who}', '/50%25/fred');
    assertExpansionEqual('{/who,dub}', '/fred/me%2Ftoo');
    assertExpansionEqual('{/var}', '/value');
    assertExpansionEqual('{/var,empty}', '/value/');
    assertExpansionEqual('{/var,undef}', '/value');
    assertExpansionEqual('{/var,x}/here', '/value/1024/here');
    assertExpansionEqual('{/var:1,var}', '/v/value');
    assertExpansionEqual('{/list}', '/red,green,blue');
    assertExpansionEqual('{/list*}', '/red/green/blue');
    assertExpansionEqual('{/list*,path:4}', '/red/green/blue/%2Ffoo');
    assertExpansionEqual('{/keys}', '/semi,%3B,dot,.,comma,%2C');
    assertExpansionEqual('{/keys*}', '/semi=%3B/dot=./comma=%2C');
  });

  test('parameter expansion', () {
    assertExpansionEqual('{;who}', ';who=fred');
    assertExpansionEqual('{;half}', ';half=50%25');
    assertExpansionEqual('{;empty}', ';empty');
    assertExpansionEqual('{;v,empty,who}', ';v=6;empty;who=fred');
    assertExpansionEqual('{;v,bar,who}', ';v=6;who=fred');
    assertExpansionEqual('{;x,y}', ';x=1024;y=768');
    assertExpansionEqual('{;x,y,empty}', ';x=1024;y=768;empty');
    assertExpansionEqual('{;x,y,undef}', ';x=1024;y=768');
    assertExpansionEqual('{;hello:5}', ';hello=Hello');
    assertExpansionEqual('{;list}', ';list=red,green,blue');
    assertExpansionEqual('{;list*}', ';list=red;list=green;list=blue');
    assertExpansionEqual('{;keys}', ';keys=semi,%3B,dot,.,comma,%2C');
    assertExpansionEqual('{;keys*}', ';semi=%3B;dot=.;comma=%2C');
  });

  test('query expansion', () {
    assertExpansionEqual('{?who}', '?who=fred');
    assertExpansionEqual('{?half}', '?half=50%25');
    assertExpansionEqual('{?x,y}', '?x=1024&y=768');
    assertExpansionEqual('{?x,y,empty}', '?x=1024&y=768&empty=');
    assertExpansionEqual('{?x,y,undef}', '?x=1024&y=768');
    assertExpansionEqual('{?var:3}', '?var=val');
    assertExpansionEqual('{?list}', '?list=red,green,blue');
    assertExpansionEqual('{?list*}', '?list=red&list=green&list=blue');
    assertExpansionEqual('{?keys}', '?keys=semi,%3B,dot,.,comma,%2C');
    assertExpansionEqual('{?keys*}', '?semi=%3B&dot=.&comma=%2C');
  });

  test('query continuation', () {
    assertExpansionEqual('{&who}', '&who=fred');
    assertExpansionEqual('{&half}', '&half=50%25');
    assertExpansionEqual('?fixed=yes{&x}', '?fixed=yes&x=1024');
    assertExpansionEqual('{&x,y,empty}', '&x=1024&y=768&empty=');
    assertExpansionEqual('{&x,y,undef}', '&x=1024&y=768');
    assertExpansionEqual('{&var:3}', '&var=val');
    assertExpansionEqual('{&list}', '&list=red,green,blue');
    assertExpansionEqual('{&list*}', '&list=red&list=green&list=blue');
    assertExpansionEqual('{&keys}', '&keys=semi,%3B,dot,.,comma,%2C');
    assertExpansionEqual('{&keys*}', '&semi=%3B&dot=.&comma=%2C');
  });
}
