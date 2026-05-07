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

final class _CountEntity extends JsonResponse {
  _CountEntity(int count) : super({'count': count});
}

final class _TestListController
    extends
        ApiControllerListConverter<
          Map<String, dynamic>,
          Map<String, dynamic>,
          _TestFailure,
          _CountEntity
        > {
  _TestListController() : super(verb: HttpMethod.POST, path: '/bulk');

  @override
  Map<String, dynamic> bodyFromMap(Map<String, dynamic> data) => data;

  @override
  Map<String, dynamic> paramsFromMap(Map<String, dynamic> data) => data;

  @override
  Future<Either<_TestFailure, _CountEntity>> processConvertedRequest(
    Request request,
    List<Map<String, dynamic>> body,
    Map<String, dynamic> params,
  ) async {
    return Right(_CountEntity(body.length));
  }
}

final class _TestListWithSchemaController extends _TestListController {
  @override
  Map<String, dynamic>? get bodySchema => {
    'type': 'array',
    'items': {
      'type': 'object',
      'properties': {
        'id': {'type': 'integer'},
      },
      'required': ['id'],
    },
  };
}

void main() {
  group('ApiControllerListConverter', () {
    test('decodes JSON array body and passes to handler', () async {
      final controller = _TestListController();

      final request = Request(
        'POST',
        Uri.parse('http://localhost/bulk'),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
        body: jsonEncode([
          {'id': 1},
          {'id': 2},
          {'id': 3},
        ]),
      );
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.ok);
      final body = jsonDecode(await response.readAsString());
      expect(body['count'], 3);
    });

    test('return s 400 on invalid JSON', () async {
      final controller = _TestListController();

      final request = Request(
        'POST',
        Uri.parse('http://localhost/bulk'),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
        body: 'not-json',
      );
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('includes BadRequestMiddleware', () async {
      final controller = _TestListController();
      expect(
        controller.middlewares.any((m) => m is BadRequestMiddleware),
        isTrue,
      );
    });

    test('bodySchema validates via converter with schema', () async {
      final controller = _TestListWithSchemaController();

      final request = Request(
        'POST',
        Uri.parse('http://localhost/bulk'),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
        body: jsonEncode([
          {'id': 1},
          {'id': 2},
        ]),
      );
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.ok);
      final body = jsonDecode(await response.readAsString());
      expect(body['count'], 2);
    });
  });
}
