import 'dart:io';

import 'package:coouter/coouter.dart';
import 'package:test/test.dart';

void main() {
  group('CookieFactory', () {
    test('set and retrieve cookies', () {
      final factory = CookieFactory(isSecure: false);
      factory.set(name: 'session', value: 'abc123');

      expect(factory.cookies.length, 1);
      expect(factory.cookies.first.name, 'session');
      expect(factory.cookies.first.value, 'abc123');
    });

    test('cookiesString returns string representations', () {
      final factory = CookieFactory(isSecure: false);
      factory.set(name: 'session', value: 'abc123');

      final strings = factory.cookiesString.toList();
      expect(strings.length, 1);
      expect(strings.first, contains('session=abc123'));
    });

    test('cookiesHeader returns header map', () {
      final factory = CookieFactory(isSecure: false);
      factory.set(name: 'session', value: 'abc123');

      final header = factory.cookiesHeader;
      expect(header.containsKey(HttpHeaders.setCookieHeader), isTrue);
      expect(header[HttpHeaders.setCookieHeader]!.length, 1);
    });

    test('empty value creates expired cookie', () {
      final factory = CookieFactory(isSecure: false);
      factory.set(name: 'old', value: '');

      final cookie = factory.cookies.first;
      expect(cookie.expires, isNotNull);
      expect(cookie.expires!.isBefore(DateTime.now()), isTrue);
    });

    test('null value creates expired cookie', () {
      final factory = CookieFactory(isSecure: false);
      factory.set(name: 'old');

      final cookie = factory.cookies.first;
      expect(cookie.value, '');
      expect(cookie.expires, isNotNull);
      expect(cookie.expires!.isBefore(DateTime.now()), isTrue);
    });

    test('isSecure sets SameSite none and secure flag', () {
      final factory = CookieFactory(isSecure: true);
      factory.set(name: 's', value: 'v');

      final cookie = factory.cookies.first;
      expect(cookie.secure, isTrue);
      expect(cookie.sameSite, SameSite.none);
    });

    test('non-secure uses SameSite lax', () {
      final factory = CookieFactory(isSecure: false);
      factory.set(name: 's', value: 'v');

      final cookie = factory.cookies.first;
      expect(cookie.secure, isFalse);
      expect(cookie.sameSite, SameSite.lax);
    });

    test('set with domain', () {
      final factory = CookieFactory(isSecure: true, domain: 'example.com');
      factory.set(name: 's', value: 'v');

      final cookie = factory.cookies.first;
      expect(cookie.domain, 'example.com');
    });
  });
}
