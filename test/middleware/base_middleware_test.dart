import 'dart:async';
import 'dart:io';

import 'package:coouter/coouter.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final class _TestMiddleware extends BaseMiddleware {
  const _TestMiddleware();

  @override
  FutureOr<Response> executor(Handler innerHandler, Request request) async {
    return innerHandler(request);
  }
}

final class _DescriptionMiddleware extends BaseMiddleware {
  const _DescriptionMiddleware();

  @override
  String? get swaggerDescription => 'Custom description';

  @override
  FutureOr<Response> executor(Handler innerHandler, Request request) async {
    return innerHandler(request);
  }
}

void main() {
  group('BaseMiddleware', () {
    test('passthrough middleware works', () async {
      const mw = _TestMiddleware();

      final handler = mw.middleware((_) async => Response.ok('ok'));
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), 'ok');
    });

    test('swaggerDescription returns null by default', () {
      const mw = _TestMiddleware();
      expect(mw.swaggerDescription, isNull);
    });

    test('swaggerDescription returns custom value when overridden', () {
      const mw = _DescriptionMiddleware();
      expect(mw.swaggerDescription, 'Custom description');
    });
  });
}
