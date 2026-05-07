# Coouter

Declarative routing for [Shelf](https://pub.dev/packages/shelf). Write type-safe API endpoints with automatic JSON conversion and OpenAPI documentation.

```yaml
dependencies:
  coouter: ^1.0.0
```

## Quick Start

```dart
import 'package:coouter/coouter.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:fpdart/fpdart.dart';

// 1. Define your error type
class AppError extends ResponseFailure {
  const AppError(this.message, {super.statusCode = 500});
  @override
  final String? message;
}

// 2. Create a simple endpoint
final healthCheck = ApiControllerHandler<AppError, JsonResponse>(
  verb: HttpMethod.GET,
  path: '/health',
  handler: (_) async => const Right(JsonResponse({'status': 'ok'})),
);

// 3. Mount and serve
void main() async {
  final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addHandler(healthCheck.handler);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server at http://localhost:8080/health');
}
```

## Concepts

### Three Layers

| Layer | When to use | Example |
|-------|------------|---------|
| **Handler** | Quick, functional style | Click → Click handler |
| **Controller** | Complex, reusable logic | Business logic in a class |
| **Group** | Multiple endpoints | API v1 with all routes |

### Two Response Types

- **Success**: `JsonResponse`, `ContentResponse`, `FileResponse`, `EmptyResponse`
- **Failure**: Extend `ResponseFailure` with your error codes

### Two Patterns

- **Either pattern**: `Either<AppError, JsonResponse>` — explicit success/error
- **Exception pattern**: Throw exceptions, let middleware catch them

## Handlers (Functional Style)

### Basic handler

```dart
final getUsers = ApiControllerHandler<AppError, JsonResponse>(
  verb: HttpMethod.GET,
  path: '/users',
  handler: (_) async => Right(JsonResponse({'users': []})),
);
```

### With params conversion

```dart
// GET /users/123 -> ctx.params = {id: '123'}
final getUser = ApiConverterControllerHandler<Map<String, dynamic>, AppError, JsonResponse>(
  path: '/users/:id',
  paramsMapper: (map) => map,  // or UserParams.fromMap
  handler: (ctx, _) async {
    final id = ctx.params['id'];
    return Right(JsonResponse({'id': id}));
  },
);
```

### With body + params

```dart
// POST /users?name=test -> ctx.body = {name: 'test'}, ctx.params = {}
final createUser = ApiConverterWithBodyConverterHandler<
  Map<String, dynamic>,  // body type
  Map<String, dynamic>,  // params type
  AppError,
  JsonResponse
>(
  path: '/users',
  paramsMapper: (map) => map,
  requestBodyMapper: (map) => map,
  handler: (ctx, _) async => Right(JsonResponse({'created': true})),
);
```

## Controllers (Class-Based)

### Simple controller

```dart
class HealthController extends ApiController<AppError, JsonResponse> {
  HealthController() : super(verb: HttpMethod.GET, path: '/health');

  @override
  Future<Either<AppError, JsonResponse>> processRequest(Request request) async =>
    const Right(JsonResponse({'status': 'ok'}));
}
```

### With params conversion

```dart
class GetUserController extends ApiConverterController<Map<String, dynamic>, AppError, JsonResponse> {
  GetUserController() : super(verb: HttpMethod.GET, path: '/users/:id');

  @override
  Mapper<Map<String, dynamic>> get paramsMapper => (map) => map;

  @override
  Process<AppError, JsonResponse, ApiControllerConverterParams<Map<String, dynamic>>>
  get processConvertedRequest => (ctx, request) async =>
    Right(JsonResponse({'id': ctx.params['id']}));
}
```

### With body + params

```dart
class CreateUserController extends ApiConverterWithBodyController<Map<String, dynamic>, Map<String, dynamic>, AppError, JsonResponse> {
  CreateUserController() : super(verb: HttpMethod.POST, path: '/users');

  @override
  Mapper<Map<String, dynamic>> get paramsMapper => (m) => m;
  @override
  Mapper<Map<String, dynamic>> get requestBodyMapper => (m) => m;

  @override
  Process<AppError, JsonResponse, ApiControllerConverterWithBodyParams<Map<String, dynamic>, Map<String, dynamic>>>
  get processConvertedRequest => (ctx, request) async =>
    Right(JsonResponse({'created': true}));
}
```

## Groups

### Group multiple controllers

```dart
class ApiV1 extends ApiGroup {
  @override
  Map<String, ApiMountable> get controllers => {
    '/health': ApiMountable.single(HealthController()),
    '/users': ApiMountable.multiple([
      GetUserController(),
      CreateUserController(),
    ]),
  };
}

// Mount at /api/v1
final router = Router()..mount('/api/v1', ApiV1().handler);
```

### Groups can include middleware

```dart
class ApiV1 extends ApiGroup {
  @override
  List<BaseMiddleware> get middlewares => [LogMiddleware()];
  
  @override
  Map<String, ApiMountable> get controllers => {...};
}
```

## Middleware

### Create middleware

```dart
class LogMiddleware extends BaseMiddleware {
  const LogMiddleware();

  @override
  FutureOr<Response> executor(Handler innerHandler, Request request) async {
    final start = DateTime.now();
    final response = await innerHandler(request);
    final duration = DateTime.now().difference(start);
    print('${request.method} ${request.url} - ${response.statusCode} (${duration.inMs}ms)');
    return response;
  }
}
```

### BadRequestMiddleware (included)

Catches `BadConversionException`, `FormatException`, and `SchemaValidationException`, returns 400:

```dart
// Already included in ApiConverterControllerHandler
// and ApiControllerListConverter
```

## Responses

```dart
// Success responses
Right(const JsonResponse({'key': 'value'}));      // 200 JSON
Right(EmptyResponse());                          // 200 empty
Right(ContentResponse(content: '<xml>', contentType: ContentType.xml));  // 200 custom

// Error responses (extend ResponseFailure)
Right(const NotFoundError('User not found'));  // uses statusCode from your class
```

### Define your errors

```dart
class AppError extends ResponseFailure {
  const AppError({required super.statusCode, super.message});
  
  factory AppError.notFound([String? msg]) => AppError(404, msg ?? 'Not found');
  factory AppError.badRequest([String? msg]) => AppError(400, msg ?? 'Bad request');
  factory AppError.internal([String? msg]) => AppError(500, msg ?? 'Error');
}
```

## OpenAPI / Swagger

### Auto-document your endpoints

Add the `SwaggerInfo` mixin:

```dart
class GetUserController extends ApiConverterController<Map<String, dynamic>, AppError, JsonResponse>
    with SwaggerInfo {
  GetUserController() : super(verb: HttpMethod.GET, path: '/users/:id');
  // ... controller implementation

  @override
  String get description => 'Get user by ID';

  @override
  bool get requiresAuth => false;

  @override
  Map<int, ResponseDoc> get responses => {
    200: ResponseDoc('User found', schema: SchemaDoc('User', {'type': 'object'})),
    404: ResponseDoc('User not found'),
  };
}
```

### Serve Swagger UI

```dart
final api = ApiV1();

final router = Router()
  ..mount('/api/v1', api.handler)
  ..mount('/docs', SwaggerController(apiRouter: api).handler);

await shelf_io.serve(router.call, 'localhost', 8080);
// Visit http://localhost:8080/docs/
```

Three endpoints:
- `GET /docs/` — Swagger UI
- `GET /docs/openapi.json` — OpenAPI 3.0 spec
- `GET /docs/schemas.json` — Component schemas

## Installation

```yaml
dependencies:
  coouter: ^1.0.0

dev_dependencies:
  test: ^1.25.0
```

## License

MIT