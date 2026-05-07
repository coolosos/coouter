import 'dart:convert';
import 'dart:io';

import 'package:coouter/coouter.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final class _TestFailure extends ResponseFailure {
  const _TestFailure({required super.statusCode});

  @override
  List<Object?> get props => [message, statusCode, headers];
}

final class _SuccessEntity extends JsonResponse {
  const _SuccessEntity() : super(const {'result': 'ok'});
}

Map<String, dynamic> _mapper(Map<String, dynamic> data) => data;

Either<_TestFailure, _SuccessEntity> _ok() =>
    Right<_TestFailure, _SuccessEntity>(const _SuccessEntity());

void main() {
  group('ApiConverterControllerHandler', () {
    test('params are passed to handler', () async {
      final controller =
          ApiConverterControllerHandler<
            void,
            Map<String, dynamic>,
            _TestFailure,
            _SuccessEntity
          >(
            path: '/search',
            verb: HttpMethod.GET,
            paramsMapper: _mapper,
            handler: (ctx, _) async {
              expect(ctx.params, containsPair('q', 'dart'));
              return _ok();
            },
          );

      final request = Request(
        'GET',
        Uri.parse('http://localhost/search?q=dart'),
      );
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.ok);
    });

    test('has BadRequestMiddleware included', () async {
      final controller =
          ApiConverterControllerHandler<
            void,
            Map<String, dynamic>,
            _TestFailure,
            _SuccessEntity
          >(
            path: '/search',
            verb: HttpMethod.GET,
            paramsMapper: _mapper,
            handler: (_, __) async => _ok(),
          );

      expect(controller.middlewares.length, 1);
      expect(controller.middlewares.first, isA<BadRequestMiddleware>());
    });
  });

  group('ApiConverterWithBodyConverterHandler', () {
    test('body and params are passed to handler', () async {
      final controller =
          ApiConverterWithBodyConverterHandler<
            Map<String, dynamic>,
            Map<String, dynamic>,
            _TestFailure,
            _SuccessEntity
          >(
            path: '/users',
            requestBodyMapper: _mapper,
            paramsMapper: _mapper,
            verb: HttpMethod.POST,
            handler: (ctx, _) async {
              expect(ctx.params, containsPair('role', 'admin'));
              expect(ctx.body, containsPair('name', 'test'));
              return _ok();
            },
          );

      final request = Request(
        'POST',
        Uri.parse('http://localhost/users?role=admin'),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
        body: jsonEncode({'name': 'test'}),
      );
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.ok);
    });

    test('return s 400 on invalid JSON body', () async {
      final controller =
          ApiConverterWithBodyConverterHandler<
            Map<String, dynamic>,
            Map<String, dynamic>,
            _TestFailure,
            _SuccessEntity
          >(
            path: '/users',
            requestBodyMapper: _mapper,
            paramsMapper: _mapper,
            verb: HttpMethod.POST,
            handler: (_, __) async => _ok(),
          );

      final request = Request(
        'POST',
        Uri.parse('http://localhost/users'),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
        body: 'not-json',
      );
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('supports optional requestBodySchema', () async {
      final controller =
          ApiConverterWithBodyConverterHandler<
            Map<String, dynamic>,
            Map<String, dynamic>,
            _TestFailure,
            _SuccessEntity
          >(
            path: '/validate',
            requestBodyMapper: _mapper,
            paramsMapper: _mapper,
            requestBodySchema: {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
              'required': ['name'],
            },
            verb: HttpMethod.POST,
            handler: (_, __) async => _ok(),
          );

      expect(controller.requestBodySchema, isNotNull);

      final request = Request(
        'POST',
        Uri.parse('http://localhost/validate'),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
        body: jsonEncode({'name': 'test'}),
      );
      final response = await controller.handler(request);
      expect(response.statusCode, HttpStatus.ok);
    });

    test('has default verb POST', () async {
      final controller =
          ApiConverterWithBodyConverterHandler<
            Map<String, dynamic>,
            Map<String, dynamic>,
            _TestFailure,
            _SuccessEntity
          >(
            path: '/default',
            requestBodyMapper: _mapper,
            paramsMapper: _mapper,
            handler: (_, __) async => _ok(),
          );

      expect(controller.verb, HttpMethod.POST);
    });
  });
}
