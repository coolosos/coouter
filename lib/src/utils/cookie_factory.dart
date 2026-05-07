import 'dart:io';

class CookieFactory {
  CookieFactory({this.isSecure = true, this.domain});

  final bool isSecure;
  final String? domain;
  final Map<String, Cookie> _cookieMap = {};

  void set({required String name, String? value, DateTime? expires}) {
    _cookieMap[name] = _buildCookie(name: name, value: value, expiry: expires);
  }

  List<Cookie> get cookies => _cookieMap.values.toList();

  Iterable<String> get cookiesString =>
      _cookieMap.values.map((e) => e.toString());

  Map<String, List<String>> get cookiesHeader => {
    HttpHeaders.setCookieHeader: cookiesString.toList(),
  };

  Cookie _buildCookie({required String name, String? value, DateTime? expiry}) {
    final finalValue = value ?? '';
    var finalExpiry = expiry;

    if (finalValue.isEmpty) {
      //! If value is empty or null, it's an expired cookie
      finalExpiry = DateTime.now().subtract(const Duration(days: 1));
    }
    // else {
    //   finalExpiry = expiry ?? DateTime.now().add(const Duration(days: 30));
    // }

    final cookie = Cookie(name, finalValue)
      ..httpOnly = false
      ..sameSite = isSecure ? SameSite.none : SameSite.lax
      ..path = '/'
      ..expires = finalExpiry;

    if (isSecure) {
      cookie
        ..secure = true
        ..domain = domain;
    }

    return cookie;
  }
}
