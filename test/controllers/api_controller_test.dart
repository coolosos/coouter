import 'dart:io';

import 'package:coouter/coouter.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final class _TestFailure extends ResponseFailure {
  const _TestFailure({required super.statusCode, super.message});

  @override
  List<Object?> get props => [message, statusCode, headers];
}

final class _OkEntity extends JsonResponse {
  const _OkEntity() : super(const {'status': 'ok'});
}

void main() {
  group('ApiControllerHandler', () {
    test('return s 200 on success', () async {
      final controller = ApiControllerHandler<_TestFailure, _OkEntity>(
        verb: HttpMethod.GET,
        path: '/health',
        handler: (_) async => const _OkEntity(),
        errorHandler: (_, __) async => const _TestFailure(statusCode: 500),
      );

      final request = Request('GET', Uri.parse('http://localhost/health'));
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.ok);
    });

    test('return s failure status code when handler throws', () async {
      final controller = ApiControllerHandler<_TestFailure, _OkEntity>(
        verb: HttpMethod.GET,
        path: '/health',
        handler: (_) async => throw Exception('fail'),
        errorHandler: (_, __) async =>
            const _TestFailure(statusCode: 503, message: 'Service Unavailable'),
      );

      final request = Request('GET', Uri.parse('http://localhost/health'));
      final response = await controller.handler(request);

      expect(response.statusCode, 503);
    });

    test('route does not match different path', () async {
      final controller = ApiControllerHandler<_TestFailure, _OkEntity>(
        verb: HttpMethod.GET,
        path: '/health',
        handler: (_) async => const _OkEntity(),
        errorHandler: (_, __) async => const _TestFailure(statusCode: 500),
      );

      final request = Request('GET', Uri.parse('http://localhost/other'));
      final response = await controller.handler(request);

      expect(response.statusCode, 404);
    });

    test('handler rethrows if errorHandler throws', () async {
      final controller = ApiControllerHandler<_TestFailure, _OkEntity>(
        verb: HttpMethod.GET,
        path: '/health',
        handler: (_) async => throw Exception('boom'),
        errorHandler: (_, __) async => throw Exception('error handler failed'),
      );

      final request = Request('GET', Uri.parse('http://localhost/health'));

      expect(() => controller.handler(request), throwsA(isA<Exception>()));
    });
  });
}
