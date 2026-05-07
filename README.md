# 🛸 Coouter

[![Pub Version](https://img.shields.io/pub/v/coouter?style=flat-square&color=blue)](https://pub.dev/packages/coouter)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](https://github.com/coolosos/coouter/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-dart%20%7C%20server-orange?style=flat-square)](https://dart.dev)

**Coouter** is a high-level abstraction layer for [Shelf](https://pub.dev/packages/shelf) designed for developers who demand **type safety**, **declarative architecture**, and **automatic documentation**.

Eliminate JSON validation boilerplate, manual error handling, and Swagger synchronization. With Coouter, your code *is* your documentation.

---

## ✨ Key Features

- 🛡️ **Total Type Safety**: Native integration with `fpdart` using the `Either<Failure, Success>` pattern.
- 🧱 **Declarative Architecture**: Organize your logic into reusable Controllers, Handlers, and Routers.
- 📝 **Swagger/OpenAPI 3.0**: Automatic specification generation and included Swagger UI server.
- 🔄 **Smart Mapping**: Automatic conversion of Body and Query Params to Dart models with integrated validation.
- 🧩 **Middleware Composition**: Apply cross-cutting logic at the router, controller, or individual route level.
- 🚀 **Shelf-Ready**: Fully compatible with the entire Shelf middleware ecosystem.

---

## 📦 Installation

Add `coouter` to your `pubspec.yaml`:

```yaml
dependencies:
  coouter: ^1.0.0
```

Or run it in your terminal:

```bash
dart pub add coouter
```

---

## 🏛️ The Three Pillars

Coouter is built on three fundamental structures to organize your API:

### 1. Handlers (Functional Style)
Ideal for rapid prototyping or simple endpoints.

```dart
final healthCheck = ApiControllerHandler<MyError, JsonResponse>(
  verb: HttpMethod.GET,
  path: '/health',
  handler: (request) async => Right(JsonResponse({'status': 'alive'})),
);
```

### 2. Controllers (Class-Based Style)
Perfect for complex logic and reusability. Allows for dependency injection and state management.

```dart
class GetUserController extends ApiConverterController<UserParams, AppError, JsonResponse> {
  GetUserController() : super(verb: HttpMethod.GET, path: '/users/:id');

  @override
  UserParams paramsMapper(Map<String, dynamic> map) => UserParams.fromMap(map);

  @override
  get processConvertedRequest => (ctx, request) async {
    final user = await repository.findById(ctx.params.id);
    return user != null 
      ? Right(JsonResponse(user.toMap()))
      : Left(AppError.notFound('User not found'));
  };
}
```

### 3. Routers (Composition)
Group controllers under common prefixes and middlewares.

```dart
class ApiV1 extends ApiRouter {
  @override
  List<BaseMiddleware> get middlewares => [AuthMiddleware()];

  @override
  Map<String, ApiMountable> get controllers => {
    '/users': ApiMountable.multiple([GetUserController(), CreateUserController()]),
    '/status': ApiMountable.single(healthCheck),
  };
}
```

---

## 🛡️ Typed Error Handling

Forget about infinite `try-catch` blocks. Coouter uses `Either` to force you to handle errors explicitly. Define your failures by extending `ResponseFailure`:

```dart
class AppError extends ResponseFailure {
  const AppError(this.message, {super.statusCode = 500});
  @override
  final String? message;

  factory AppError.notFound(String msg) => AppError(msg, statusCode: 404);
}
```

---

## 📝 Live Documentation (Swagger)

Add the `SwaggerInfo` mixin to your controllers to automatically generate the OpenAPI specification:

```dart
class CreateUserController extends ApiConverterWithBodyController<UserBody, NoParams, AppError, JsonResponse> 
    with SwaggerInfo {
  
  @override
  String get description => 'Creates a new user in the system';

  @override
  Map<int, ResponseDoc> get responses => {
    201: ResponseDoc('User created successfully', schema: SchemaDoc.name('User')),
    400: ResponseDoc('Invalid data'),
  };
}
```

To serve the documentation, simply add the `SwaggerController`:

```dart
final router = Router()
  ..mount('/api/v1', apiV1.handler)
  ..mount('/docs', SwaggerController(apiRouter: apiV1).handler);
```
Access `http://localhost:8080/docs/` and you'll see your Swagger UI ready to use.

---

## 🚀 Full Example in 30 Seconds

```dart
import 'package:coouter/coouter.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final api = ApiV1(); // Your route group
  
  final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addHandler(api.handler);

  await shelf_io.serve(handler, '0.0.0.0', 8080);
  print('🚀 Server flying at http://localhost:8080');
}
```

---

## 🤝 Contributions

Contributions are welcome! If you have an idea for a new feature or have found a bug, please open an Issue or a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
