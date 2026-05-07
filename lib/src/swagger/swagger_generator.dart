// ignore_for_file: avoid_print for debug

import 'dart:io';

import 'package:shelf/shelf.dart';

import '../api/api_router.dart';
import '../controllers/api_controller_handler.dart';
import '../controllers/base_controller.dart';
import '../controllers/api_converter_with_body_controller.dart';
import '../core/internal_server_error.dart';
import '../core/response_entity.dart';
import '../core/response_failure.dart';
import '../middleware/base_middleware.dart';
import '../utils/http_method.dart';

class SwaggerInfoImpl implements SwaggerInfo {
  const SwaggerInfoImpl({
    this.description = '',
    this.descriptionBody = '',
    this.requiresAuth = false,
    this.responses = const {},
    this.dependentSchemas = const [],
    this.requestBodySchema = const {},
    this.parameters = const [],
  });

  @override
  final String description;
  @override
  final String descriptionBody;

  @override
  final bool requiresAuth;

  @override
  final Map<int, ResponseDoc> responses;

  @override
  final List<SchemaDoc> dependentSchemas;

  @override
  final Map<String, dynamic>? requestBodySchema;

  @override
  final List<ParamDoc> parameters;
}

SwaggerInfo? _mergeSwaggerInfo(SwaggerInfo? parent, SwaggerInfo? child) {
  if (parent == null) return child;
  if (child == null) return parent;

  return SwaggerInfoImpl(
    description: [
      parent.description,
      child.description,
    ].where((s) => s.isNotEmpty).join('<br>'),
    descriptionBody: [
      parent.descriptionBody,
      child.descriptionBody,
    ].where((s) => s != null && s.isNotEmpty).join('<br>'),
    requiresAuth: child.requiresAuth || parent.requiresAuth,
    responses: {...parent.responses, ...child.responses},
    dependentSchemas: [...parent.dependentSchemas, ...child.dependentSchemas],
    requestBodySchema: child.requestBodySchema ?? parent.requestBodySchema,
    parameters: [...parent.parameters, ...child.parameters],
  );
}

List<Map<String, dynamic>> _buildParametersFromDocs(List<ParamDoc> docs) {
  return docs.map((doc) => doc.toOpenApi()).toList();
}

List<Map<String, dynamic>> _mergeAllParameters({
  required String mountedPath,
  required SwaggerInfo? swaggerInfo,
}) {
  /// Path params detectados automáticamente desde /users/<id>
  final pathParameters = _extractPathParameters(mountedPath);

  /// Params definidos manualmente en el controller
  final documentedParameters = _buildParametersFromDocs(
    swaggerInfo?.parameters ?? const [],
  );

  /// Evitar duplicados
  final merged = [
    ...pathParameters,
    ...documentedParameters.where(
      (doc) => !pathParameters.any(
        (auto) => auto['name'] == doc['name'] && auto['in'] == doc['in'],
      ),
    ),
  ];

  return merged;
}

Map<String, dynamic> _fixRefs(Map<String, dynamic> schema) {
  final newMap = <String, dynamic>{};
  schema.forEach((key, value) {
    if (key == r'$ref' && value is String && !value.startsWith('#')) {
      newMap[key] = '#/components/schemas/$value';
    } else if (value is Map<String, dynamic>) {
      newMap[key] = _fixRefs(value);
    } else if (value is List) {
      newMap[key] = value.map((item) {
        if (item is Map<String, dynamic>) {
          return _fixRefs(item);
        }
        return item;
      }).toList();
    } else {
      newMap[key] = value;
    }
  });
  return newMap;
}

List<Map<String, dynamic>> _extractPathParameters(String path) {
  final parameterRegExp = RegExp('<([^>]+)>');
  final parameters = <Map<String, dynamic>>[];
  for (final match in parameterRegExp.allMatches(path)) {
    final paramName = match.group(1)!;
    parameters.add({
      'name': paramName,
      'in': 'path',
      'required': true,
      'schema': {'type': 'string'},
    });
  }
  return parameters;
}

void _processDependentSchemas(
  SwaggerInfo? swaggerInfo,
  Map<String, dynamic> componentSchemas,
) {
  if (swaggerInfo?.dependentSchemas case final dependentSchemas?) {
    for (final doc in dependentSchemas) {
      if (!componentSchemas.containsKey(doc.name)) {
        final schema = _fixRefs(doc.schema);
        componentSchemas[doc.name] = schema;
      }
    }
  }
}

String _addMiddlewareDescriptions(List<BaseMiddleware> middlewares) {
  return middlewares
      .map((mw) => mw.swaggerDescription)
      .whereType<String>()
      .join('</br>');
}

Map<String, dynamic> _prepareOpenApiResponses(
  SwaggerInfo? swaggerInfo,
  Map<String, dynamic> componentSchemas,
  String tag,
  String path,
  bool isProxy,
) {
  final openApiResponses = <String, dynamic>{};
  if (swaggerInfo?.responses case final responses?) {
    for (final responseEntry in responses.entries) {
      final statusCode = responseEntry.key.toString();
      final responseDoc = responseEntry.value;
      final responseDef = <String, dynamic>{
        'description': responseDoc.description,
      };

      // Headers
      if (responseDoc.headersSchema != null) {
        final headersSchema = responseDoc.headersSchema!;
        final responseHeaders = <String, dynamic>{};

        if (headersSchema['properties'] is Map) {
          final properties =
              headersSchema['properties'] as Map<String, dynamic>;
          for (final entry in properties.entries) {
            final headerName = entry.key;
            final headerDef = entry.value as Map<String, dynamic>;

            responseHeaders[headerName] = {
              'description': headerDef['description'] ?? 'Header $headerName',
              'schema': {
                'type': headerDef['type'] ?? 'string',
                if (headerDef['format'] != null) 'format': headerDef['format'],
                if (headerDef['default'] != null)
                  'default': headerDef['default'],
              },
            };
          }
        }

        if (responseHeaders.isNotEmpty) {
          responseDef['headers'] = responseHeaders;
        }
      }

      // Links
      if (responseDoc.links != null && responseDoc.links!.isNotEmpty) {
        final responseLinks = <String, dynamic>{};
        for (final linkEntry in responseDoc.links!.entries) {
          responseLinks[linkEntry.key] = {
            'operationId': linkEntry.value.operationId,
            'parameters': linkEntry.value.parameters,
            if (linkEntry.value.description != null)
              'description': linkEntry.value.description,
          };
        }
        responseDef['links'] = responseLinks;
      }

      // Schema
      if (responseDoc.schema != null) {
        final schemaName =
            responseDoc.schema?.name ??
            '${isProxy ? 'Proxy' : ''}${tag.replaceAll('/', '')}${path.replaceAll('/', '_')}_$statusCode';
        if (!componentSchemas.containsKey(schemaName)) {
          final schema = _fixRefs(responseDoc.schema!.schema);
          componentSchemas[schemaName] = schema;
        }
        responseDef['content'] = {
          'application/json': {
            'schema': {r'$ref': '#/components/schemas/$schemaName'},
          },
        };
      }
      openApiResponses[statusCode] = responseDef;
    }
  }
  return openApiResponses;
}

({SwaggerInfo? mergedSwaggerInfo, String mountedPath, String openApiPath})
_preparePathInfo(
  BaseController controller,
  SwaggerInfo? parentSwaggerInfo,
  String tag,
) {
  final currentSwaggerInfo = controller is SwaggerInfo
      ? controller as SwaggerInfo
      : null;
  final mergedSwaggerInfo = _mergeSwaggerInfo(
    parentSwaggerInfo,
    currentSwaggerInfo,
  );

  final String path = (controller as dynamic).path;
  final mountedPath = tag == '/' ? path : '$tag$path';

  final openApiPath = mountedPath.replaceAllMapped(
    RegExp('<([^>]+)>'),
    (match) => '{${match.group(1)}}',
  );
  return (
    mergedSwaggerInfo: mergedSwaggerInfo,
    mountedPath: mountedPath,
    openApiPath: openApiPath,
  );
}

void _addSecurityInfo(Map<String, dynamic> operation, bool needsAuth) {
  if (needsAuth) {
    operation['security'] = [
      {'BearerAuth': []},
    ];
  }
}

Map<String, dynamic> _buildOperation({
  required String operationId,
  required String summary,
  required String? description,
  required String tag,
  required List<Map<String, dynamic>> parameters,
  required Map<String, dynamic> responses,
  required bool needsAuth,
  Map<String, dynamic>? requestBody,
}) {
  final operation = <String, dynamic>{
    'operationId': operationId,
    'summary': summary,
    if (description != null) 'description': description,
    'tags': [tag],
    if (parameters.isNotEmpty) 'parameters': parameters,
    'responses': responses,
  };

  if (requestBody != null) {
    operation['requestBody'] = requestBody;
  }

  _addSecurityInfo(operation, needsAuth);

  return operation;
}

void _processController(
  BaseController controller,
  String tag,
  Map<String, dynamic> paths,
  Map<String, dynamic> componentSchemas,
  SwaggerInfo? parentSwaggerInfo,
  List<BaseMiddleware> parentMiddlewares,
) {
  final allMiddlewares = [...parentMiddlewares, ...controller.middlewares];

  switch (controller) {
    case ApiControllers():
      _apiControllers(
        controller,
        parentSwaggerInfo,
        tag,
        paths,
        componentSchemas,
        allMiddlewares,
      );
    case ApiController():
      _apiController(
        controller,
        parentSwaggerInfo,
        tag,
        allMiddlewares,
        componentSchemas,
        paths,
      );
    case ProxyController():
      _proxyController(
        controller,
        parentSwaggerInfo,
        tag,
        allMiddlewares,
        componentSchemas,
        paths,
      );
  }
}

void _proxyController(
  ProxyController controller,
  SwaggerInfo? parentSwaggerInfo,
  String tag,
  List<BaseMiddleware> allMiddlewares,
  Map<String, dynamic> componentSchemas,
  Map<String, dynamic> paths,
) {
  final (:mergedSwaggerInfo, :mountedPath, :openApiPath) = _preparePathInfo(
    controller,
    parentSwaggerInfo,
    tag,
  );

  final path = controller.path;

  final summary =
      mergedSwaggerInfo?.description ??
      'Proxy endpoint for $openApiPath (all HTTP methods)';

  final description = StringBuffer();

  final needsAuth = mergedSwaggerInfo?.requiresAuth ?? false;

  final parameters = _mergeAllParameters(
    mountedPath: mountedPath,
    swaggerInfo: mergedSwaggerInfo,
  );

  final mwDesc = _addMiddlewareDescriptions(allMiddlewares);
  if (mwDesc.isNotEmpty) description.write(mwDesc);

  if (mergedSwaggerInfo?.descriptionBody case final desk?) {
    description
      ..write('</br>')
      ..write(desk);
  }

  _processDependentSchemas(mergedSwaggerInfo, componentSchemas);

  final openApiResponses = _prepareOpenApiResponses(
    mergedSwaggerInfo,
    componentSchemas,
    tag,
    path,
    true,
  );

  if (openApiResponses.isEmpty) {
    openApiResponses['200'] = {'description': 'Successful proxy operation'};
    openApiResponses['502'] = {
      'description': 'Bad Gateway - Error al procesar la solicitud proxy',
    };
  }

  final requestBody =
      mergedSwaggerInfo?.requestBodySchema ??
      {
        'description': 'Request body (formato flexible para proxy)',
        'content': {
          'application/json': {
            'schema': {
              'type': 'object',
              'description': 'Contenido dinámico del proxy',
            },
          },
          'application/x-www-form-urlencoded': {
            'schema': {'type': 'object'},
          },
          'multipart/form-data': {
            'schema': {'type': 'object'},
          },
        },
      };

  final httpMethods = [
    'get',
    'post',
    'put',
    'delete',
    'patch',
    'head',
    'options',
  ];

  final routeDef = <String, dynamic>{};

  for (final verb in httpMethods) {
    final operationId = (verb + openApiPath)
        .replaceAll(RegExp('[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    Map<String, dynamic>? operationRequestBody;
    if (['post', 'put', 'patch'].contains(verb)) {
      operationRequestBody = requestBody;
    }

    final operation = _buildOperation(
      operationId: '${operationId}_proxy',
      summary: '$summary (${verb.toUpperCase()}) ($operationId)',
      description: description.toString(),
      tag: tag,
      parameters: parameters,
      responses: openApiResponses,
      needsAuth: needsAuth,
      requestBody: operationRequestBody,
    );

    routeDef[verb] = operation;
  }

  paths[openApiPath] = routeDef;
}

void _apiController(
  ApiController<ResponseFailure, ResponseEntity> controller,
  SwaggerInfo? parentSwaggerInfo,
  String tag,
  List<BaseMiddleware> allMiddlewares,
  Map<String, dynamic> componentSchemas,
  Map<String, dynamic> paths,
) {
  final (:mergedSwaggerInfo, :mountedPath, :openApiPath) = _preparePathInfo(
    controller,
    parentSwaggerInfo,
    tag,
  );

  final path = controller.path;
  final verb = controller.verb.name.toLowerCase();

  String summary;
  final description = StringBuffer();

  var needsAuth = false;

  summary = mergedSwaggerInfo?.description ?? 'API endpoint for $openApiPath';
  needsAuth = mergedSwaggerInfo?.requiresAuth ?? false;
  final parameters = _mergeAllParameters(
    mountedPath: mountedPath,
    swaggerInfo: mergedSwaggerInfo,
  );

  final mwDesc = _addMiddlewareDescriptions(allMiddlewares);
  if (mwDesc.isNotEmpty) description.write(mwDesc);

  if (mergedSwaggerInfo?.descriptionBody case final desk?) {
    description
      ..write('</br>')
      ..write(desk);
  }

  _processDependentSchemas(mergedSwaggerInfo, componentSchemas);

  final openApiResponses = _prepareOpenApiResponses(
    mergedSwaggerInfo,
    componentSchemas,
    tag,
    path,
    false,
  );

  if (openApiResponses.isEmpty) {
    openApiResponses['200'] = {'description': 'Successful operation'};
  }

  final operationId = (verb + openApiPath)
      .replaceAll(RegExp('[^a-zA-Z0-9]'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  Map<String, dynamic>? requestBody;
  if (controller is ApiConverterWithBodyController) {
    final schema = controller.requestBodySchema;
    final rawRequestBodySchema =
        schema ??
        <String, dynamic>{
          'type': 'object',
          'description': 'Body for $mountedPath',
        };
    final requestBodySchema = _fixRefs(rawRequestBodySchema);
    requestBody = {
      'required': true,
      'content': {
        'application/json': {'schema': requestBodySchema},
      },
    };
  }

  final operation = _buildOperation(
    operationId: operationId,
    summary: '$summary ($operationId)',
    description: description.toString(),
    tag: tag,
    parameters: parameters,
    responses: openApiResponses,
    needsAuth: needsAuth,
    requestBody: requestBody,
  );

  final routeDef = {verb: operation};
  paths[openApiPath] = routeDef;
}

void _apiControllers(
  ApiControllers controller,
  SwaggerInfo? parentSwaggerInfo,
  String tag,
  Map<String, dynamic> paths,
  Map<String, dynamic> componentSchemas,
  List<BaseMiddleware> allMiddlewares,
) {
  final currentSwaggerInfo = controller is SwaggerInfo
      ? controller as SwaggerInfo
      : null;
  final mergedSwaggerInfo = _mergeSwaggerInfo(
    parentSwaggerInfo,
    currentSwaggerInfo,
  );
  for (final route in controller.routes) {
    _processController(
      route,
      tag,
      paths,
      componentSchemas,
      mergedSwaggerInfo,
      allMiddlewares,
    );
  }
}

Map<String, dynamic> _generateOpenApiSpec(ApiRouter apiRouter) {
  final openApiSpec = {
    'openapi': '3.0.0',
    'info': {
      'title': 'API Documentation',
      'version': '1.0.0',
      'description': 'Generated from Shelf Router',
    },
    'servers': [
      {'url': '/'},
    ],
    'paths': <String, dynamic>{},
    'tags': <Map<String, String>>[],
    'components': {
      'securitySchemes': {
        'BearerAuth': {
          'type': 'http',
          'scheme': 'bearer',
          'bearerFormat': 'JWT',
          'description':
              'Introduce el token JWT con el prefijo "Bearer ". Ejemplo: "Bearer {token}"',
        },
      },
      'schemas': <String, dynamic>{
        'Error': {
          'type': 'object',
          'properties': {
            'code': {'type': 'integer', 'description': 'Código de error.'},
            'message': {
              'type': 'string',
              'description': 'Descripción del error.',
            },
          },
        },
      },
    },
  };

  final paths = openApiSpec['paths']! as Map<String, dynamic>;
  final tags = openApiSpec['tags']! as List<Map<String, String>>;
  final components = openApiSpec['components']! as Map<String, dynamic>;
  final componentSchemas = components['schemas'] as Map<String, dynamic>;

  for (final entry in apiRouter.controllers.entries) {
    final tag = entry.key;

    tags.add({
      'name': tag,
      'description': 'Endpoints for the "$tag" mount point.',
    });

    for (final controller in entry.value.asList) {
      _processController(
        controller,
        tag,
        paths,
        componentSchemas,
        null,
        apiRouter.middlewares,
      );
    }
  }

  return openApiSpec;
}

final class SwaggerController extends ApiControllers {
  SwaggerController({required this.apiRouter});
  final ApiRouter apiRouter;

  @override
  List<BaseController> get routes => [
    ApiControllerHandler<InternalServerError, JsonResponse>(
      verb: HttpMethod.GET,
      path: '/api-docs/schemas.json',
      handler: (Request request) async {
        try {
          final fullSpec = _generateOpenApiSpec(apiRouter);
          final schemas =
              (fullSpec['components'] as Map<String, dynamic>)['schemas'];
          return JsonResponse(schemas as Map<String, dynamic>);
        } catch (e, s) {
          print('Error generating schemas JSON: $e');
          print(s);
          rethrow;
        }
      },
      errorHandler: (p0, p1) async => const InternalServerError(),
    ),
    ApiControllerHandler<InternalServerError, JsonResponse>(
      verb: HttpMethod.GET,
      path: '/api-docs/openapi.json',
      handler: (Request request) async {
        try {
          return JsonResponse(_generateOpenApiSpec(apiRouter));
        } catch (e, s) {
          print('Error generating OpenAPI spec: $e');
          print(s);
          rethrow;
        }
      },
      errorHandler: (p0, p1) async => const InternalServerError(),
    ),
    ApiControllerHandler<InternalServerError, ContentResponse>(
      verb: HttpMethod.GET,
      path: '/api-docs/',
      handler: (Request request) async {
        const swaggerUiHtml = '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>API Documentation</title>
    <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.29.0/swagger-ui.min.css" />
  </head>
  <body>
    <div id="swagger-ui"></div>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.29.0/swagger-ui-bundle.js"></script>
    <script>
      window.onload = function() {
        SwaggerUIBundle({
          url: "./openapi.json",
          dom_id: "#swagger-ui",
          deepLinking: true,
          docExpansion: "none",
          defaultModelsExpandDepth: 3,
          filter: false,
          presets: [
            SwaggerUIBundle.presets.apis,
            SwaggerUIBundle.SwaggerUIStandalonePreset
          ],
          layout: "BaseLayout",
          syntaxHighlight: {
            activate: true,
            theme: "obsidian"
          }
        });
      };
    </script>
  </body>
</html>
''';
        return ContentResponse(
          content: swaggerUiHtml,
          contentType: ContentType.html,
        );
      },
      errorHandler: (p0, p1) async => const InternalServerError(),
    ),
  ];
}
