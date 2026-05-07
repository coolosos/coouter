import 'dart:async';
import 'dart:convert';
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

ApiControllerHandler<_TestFailure, _OkEntity> _handler(String path) {
  return ApiControllerHandler<_TestFailure, _OkEntity>(
    verb: HttpMethod.GET,
    path: path,
    handler: (_) async => const _OkEntity(),
    errorHandler: (_, __) async => const _TestFailure(statusCode: 500),
  );
}

final class _TestGroup extends ApiGroup {
  @override
  Map<String, ApiMountable> get controllers => {
    '/ping': ApiMountable.single(_handler('/ping')),
    '/items': ApiMountable.multiple([
      _handler('/items'),
      _handler('/items/<id>'),
    ]),
  };
}

final class _ProxyGroup extends ApiGroup {
  @override
  Map<String, ApiMountable> get controllers => {
    '/proxy': ApiMountable.single(_ProxyCtrl()),
  };
}

final class _ProxyCtrl extends ProxyController {
  _ProxyCtrl() : super(path: '/<rest|.*>');

  @override
  Future<Response> processRequest(Request request) async {
    return Response.ok('proxy');
  }
}

// --- Auth test ---

final class _AuthControllers extends ApiControllers with SwaggerInfo {
  @override
  List<BaseController> get routes => [_handler('/secure')];

  @override
  String get description => 'Secure endpoint';

  @override
  bool get requiresAuth => true;

  @override
  Map<int, ResponseDoc> get responses => const {};
}

final class _AuthGroup extends ApiGroup {
  @override
  Map<String, ApiMountable> get controllers => {
    '/auth': ApiMountable.single(_AuthControllers()),
  };
}

// --- Description test ---

final class _DescControllers extends ApiControllers with SwaggerInfo {
  @override
  List<BaseController> get routes => [_handler('/items')];

  @override
  String get description => 'List items';

  @override
  String? get descriptionBody => 'Returns all items matching filters';

  @override
  Map<int, ResponseDoc> get responses => const {};
}

final class _DescGroup extends ApiGroup {
  @override
  Map<String, ApiMountable> get controllers => {
    '/desc': ApiMountable.single(_DescControllers()),
  };
}

// --- Response with headers and links test ---

final class _RespControllers extends ApiControllers with SwaggerInfo {
  @override
  List<BaseController> get routes => [_handler('/data')];

  @override
  String get description => 'Data endpoint';

  @override
  Map<int, ResponseDoc> get responses => {
    200: ResponseDoc(
      'Successful response',
      headersSchema: {
        'properties': {
          'X-Rate-Limit': {
            'type': 'integer',
            'description': 'Rate limit remaining',
          },
        },
      },
      links: {
        'next': LinkDoc(operationId: 'getNext', parameters: {'id': '123'}),
      },
    ),
  };
}

final class _RespGroup extends ApiGroup {
  @override
  Map<String, ApiMountable> get controllers => {
    '/res': ApiMountable.single(_RespControllers()),
  };
}

// --- Dependent schemas test ---

final class _SchemaControllers extends ApiControllers with SwaggerInfo {
  @override
  List<BaseController> get routes => [_handler('/users')];

  @override
  String get description => 'Users endpoint';

  @override
  List<SchemaDoc> get dependentSchemas => const [
    SchemaDoc('User', {
      'type': 'object',
      'properties': {
        'id': {'type': 'integer'},
        'name': {'type': 'string'},
      },
    }),
  ];

  @override
  Map<int, ResponseDoc> get responses => const {};
}

final class _SchemaGroup extends ApiGroup {
  @override
  Map<String, ApiMountable> get controllers => {
    '/users': ApiMountable.single(_SchemaControllers()),
  };
}

// --- Middleware with swaggerDescription test ---

final class _DescMiddleware extends BaseMiddleware {
  const _DescMiddleware();

  @override
  String? get swaggerDescription => 'Rate limited to 100 req/min';

  @override
  FutureOr<Response> executor(Handler innerHandler, Request request) async {
    return innerHandler(request);
  }
}

final class _MwGroup extends ApiGroup {
  @override
  Map<String, ApiMountable> get controllers => {
    '/mw': ApiMountable.single(_handler('/test')),
  };

  @override
  List<BaseMiddleware> get middlewares => [const _DescMiddleware()];
}

Future<Map<String, dynamic>> _getSpec(ApiGroup group) async {
  final swagger = SwaggerController(apiRouter: group);
  final request = Request(
    'GET',
    Uri.parse('http://localhost/api-docs/openapi.json'),
  );
  final response = await swagger.handler(request);
  return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
}

void main() {
  group('SwaggerController', () {
    test('openapi.json endpoint return s valid spec', () async {
      final swagger = SwaggerController(apiRouter: _TestGroup());
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api-docs/openapi.json'),
      );
      final response = await swagger.handler(request);

      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        ContentType.json.value,
      );

      final spec =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(spec['openapi'], '3.0.0');
      expect(spec['paths'], isA<Map>());
      expect((spec['paths'] as Map).isNotEmpty, isTrue);
    });

    test('schemas.json endpoint return s component schemas', () async {
      final swagger = SwaggerController(apiRouter: _TestGroup());
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api-docs/schemas.json'),
      );
      final response = await swagger.handler(request);

      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        ContentType.json.value,
      );

      final schemas =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(schemas.containsKey('Error'), isTrue);
    });

    test('swagger UI HTML endpoint', () async {
      final swagger = SwaggerController(apiRouter: _TestGroup());
      final request = Request('GET', Uri.parse('http://localhost/api-docs/'));
      final response = await swagger.handler(request);

      expect(response.statusCode, HttpStatus.ok);
      final body = await response.readAsString();
      expect(body, contains('swagger-ui'));
      expect(body, contains('openapi.json'));
    });

    test('openapi.json includes path params from <param> syntax', () async {
      final swagger = SwaggerController(apiRouter: _TestGroup());
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api-docs/openapi.json'),
      );
      final response = await swagger.handler(request);

      final spec =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final paths = spec['paths'] as Map<String, dynamic>;

      expect(paths.keys.any((k) => k.contains('{id}')), isTrue);
    });

    test('openapi.json works with ProxyController group', () async {
      final swagger = SwaggerController(apiRouter: _ProxyGroup());
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api-docs/openapi.json'),
      );
      final response = await swagger.handler(request);

      expect(response.statusCode, HttpStatus.ok);
      final spec =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final paths = spec['paths'] as Map<String, dynamic>;
      expect(paths.isNotEmpty, isTrue);
    });

    test('openapi.json includes tags for mount points', () async {
      final swagger = SwaggerController(apiRouter: _TestGroup());
      final request = Request(
        'GET',
        Uri.parse('http://localhost/api-docs/openapi.json'),
      );
      final response = await swagger.handler(request);

      final spec =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final tags = spec['tags'] as List;
      expect(tags.any((t) => t['name'] == '/ping'), isTrue);
      expect(tags.any((t) => t['name'] == '/items'), isTrue);
    });

    test('openapi.json includes security when requiresAuth is true', () async {
      final spec = await _getSpec(_AuthGroup());
      final paths = spec['paths'] as Map<String, dynamic>;

      final authPath = paths['/auth/secure'] as Map<String, dynamic>;
      final getOp = authPath['get'] as Map<String, dynamic>;
      expect(getOp['security'], isNotNull);
    });

    test('openapi.json merges description and descriptionBody', () async {
      final spec = await _getSpec(_DescGroup());
      final paths = spec['paths'] as Map<String, dynamic>;

      final path = paths['/desc/items'] as Map<String, dynamic>;
      final getOp = path['get'] as Map<String, dynamic>;
      expect(getOp['summary'], contains('List items'));
      expect(getOp['description'], contains('Returns all items'));
    });

    test('openapi.json includes response headers and links', () async {
      final spec = await _getSpec(_RespGroup());
      final paths = spec['paths'] as Map<String, dynamic>;

      final path = paths['/res/data'] as Map<String, dynamic>;
      final getOp = path['get'] as Map<String, dynamic>;
      final resp200 = getOp['responses']['200'] as Map<String, dynamic>;
      expect(resp200['headers'], isNotNull);
      expect(resp200['links'], isNotNull);
    });

    test('openapi.json includes dependent schemas', () async {
      final spec = await _getSpec(_SchemaGroup());
      final components = spec['components'] as Map<String, dynamic>;
      final schemas = components['schemas'] as Map<String, dynamic>;

      expect(schemas.containsKey('User'), isTrue);
    });

    test('openapi.json includes middleware swaggerDescription', () async {
      final spec = await _getSpec(_MwGroup());
      final paths = spec['paths'] as Map<String, dynamic>;

      final path = paths['/mw/test'] as Map<String, dynamic>;
      final getOp = path['get'] as Map<String, dynamic>;
      expect(getOp['description'], contains('Rate limited to 100 req/min'));
    });
  });
}
