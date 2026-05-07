import 'dart:async';
import 'dart:io';

import 'package:coouter/coouter.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final class _TestFailure extends ResponseFailure {
  const _TestFailure({required super.statusCode});

  @override
  List<Object?> get props => [message, statusCode, headers];
}

final class _OkEntity extends JsonResponse {
  const _OkEntity() : super(const {'ok': true});
}

final class _TestMiddleware extends BaseMiddleware {
  const _TestMiddleware();

  @override
  FutureOr<Response> executor(Handler innerHandler, Request request) async {
    final response = await innerHandler(request);
    return response.change(headers: {'x-mw': 'applied'});
  }
}

final class _GroupWithMiddleware extends ApiControllers {
  const _GroupWithMiddleware();

  @override
  List<BaseController> get routes => [
    ApiControllerHandler<_TestFailure, _OkEntity>(
      verb: HttpMethod.GET,
      path: '/a',
      handler: (_) async => const _OkEntity(),
      errorHandler: (_, __) async => const _TestFailure(statusCode: 500),
    ),
  ];

  @override
  List<BaseMiddleware> get middlewares => [const _TestMiddleware()];
}

final class _EmptyGroup extends ApiControllers {
  const _EmptyGroup();

  @override
  List<BaseController> get routes => [];
}

void main() {
  group('ApiControllers', () {
    test('routes are reachable via handler', () async {
      final group = _GroupWithMiddleware();

      final request = Request('GET', Uri.parse('http://localhost/a'));
      final response = await group.handler(request);

      expect(response.statusCode, HttpStatus.ok);
    });

    test('middleware is applied to routes', () async {
      final group = _GroupWithMiddleware();

      final request = Request('GET', Uri.parse('http://localhost/a'));
      final response = await group.handler(request);

      expect(response.headers['x-mw'], 'applied');
    });

    test('empty routes return 404', () async {
      final group = _EmptyGroup();

      final request = Request('GET', Uri.parse('http://localhost/any'));
      final response = await group.handler(request);

      expect(response.statusCode, 404);
    });
  });
}
