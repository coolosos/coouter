import 'dart:async';
import 'dart:io';

import 'package:coouter/coouter.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final class _OkEntity extends JsonResponse {
  const _OkEntity() : super(const {'ok': true});
}

final class _TestFailure extends ResponseFailure {
  const _TestFailure({required super.statusCode});

  @override
  List<Object?> get props => [message, statusCode, headers];
}

/// When mounted via ApiRouter, the controller path must be '/' since
/// shelf_router.mount strips the prefix and the inner router sees '/'.
ApiControllerHandler<_TestFailure, _OkEntity> _handler() {
  return ApiControllerHandler<_TestFailure, _OkEntity>(
    verb: HttpMethod.GET,
    path: '/',
    handler: (_) async => const _OkEntity(),
    errorHandler: (_, __) async => const _TestFailure(statusCode: 500),
  );
}

final class _TestGroup extends ApiRouter {
  @override
  Map<String, ApiMountable> get controllers => {
    '/health': ApiMountable.single(_handler()),
    '/users': ApiMountable.multiple([_handler(), _handler()]),
  };
}

final class _EmptyGroup extends ApiRouter {
  @override
  Map<String, ApiMountable> get controllers => {};
}

final class _TestMiddleware extends BaseMiddleware {
  const _TestMiddleware();

  @override
  FutureOr<Response> executor(Handler innerHandler, Request request) async {
    final response = await innerHandler(request);
    return response.change(headers: {'x-mw': 'applied'});
  }
}

final class _GroupWithMiddleware extends ApiRouter {
  @override
  Map<String, ApiMountable> get controllers => {
    '/test': ApiMountable.single(_handler()),
  };

  @override
  List<BaseMiddleware> get middlewares => [const _TestMiddleware()];
}

void main() {
  group('ApiRouter', () {
    test('single mount routes correctly', () async {
      final group = _TestGroup();
      final request = Request('GET', Uri.parse('http://localhost/health'));
      final response = await group.handler(request);
      expect(response.statusCode, HttpStatus.ok);
    });

    test('multiple mount routes correctly', () async {
      final group = _TestGroup();
      final request = Request('GET', Uri.parse('http://localhost/users'));
      final response = await group.handler(request);
      expect(response.statusCode, HttpStatus.ok);
    });

    test('return s 404 on unknown path', () async {
      final group = _TestGroup();
      final request = Request('GET', Uri.parse('http://localhost/unknown'));
      final response = await group.handler(request);
      expect(response.statusCode, 404);
    });

    test('empty controllers return 404', () async {
      final group = _EmptyGroup();
      final request = Request('GET', Uri.parse('http://localhost/any'));
      final response = await group.handler(request);
      expect(response.statusCode, 404);
    });

    test('middleware is applied to all routes', () async {
      final group = _GroupWithMiddleware();
      final request = Request('GET', Uri.parse('http://localhost/test'));
      final response = await group.handler(request);
      expect(response.headers['x-mw'], 'applied');
    });

    test(
      'handler uses middleware pipeline when middlewares non-empty',
      () async {
        final group = _GroupWithMiddleware();
        final handler = group.handler;

        final request = Request('GET', Uri.parse('http://localhost/test'));
        final response = await handler(request);
        expect(response.statusCode, HttpStatus.ok);
      },
    );
  });
}
