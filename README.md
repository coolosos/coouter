# 🛸 Coouter

[![Pub Version](https://img.shields.io/pub/v/coouter?style=flat-square&color=blue)](https://pub.dev/packages/coouter)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](https://github.com/coolosos/coouter/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-dart%20%7C%20server-orange?style=flat-square)](https://dart.dev)

**Coouter** es una capa de abstracción de alto nivel para [Shelf](https://pub.dev/packages/shelf) diseñada para desarrolladores que exigen **seguridad de tipos**, **arquitectura declarativa** y **documentación automática**.

Elimina el boilerplate de la validación de JSON, el manejo manual de errores y la sincronización de Swagger. Con Coouter, tu código *es* tu documentación.

---

## ✨ Características Principales

- 🛡️ **Seguridad de Tipos Total**: Integración nativa con `fpdart` utilizando el patrón `Either<Failure, Success>`.
- 🧱 **Arquitectura Declarativa**: Organiza tu lógica en Controladores, Handlers y Grupos reutilizables.
- 📝 **Swagger/OpenAPI 3.0**: Generación automática de especificaciones y servidor de Swagger UI incluido.
- 🔄 **Mapeo Inteligente**: Conversión automática de Body y Query Params a modelos Dart con validación integrada.
- 🧩 **Composición de Middleware**: Aplica lógica transversal a nivel de grupo, controlador o ruta individual.
- 🚀 **Shelf-Ready**: Totalmente compatible con todo el ecosistema de middleware de Shelf.

---

## 📦 Instalación

Añade `coouter` a tu `pubspec.yaml`:

```yaml
dependencies:
  coouter: ^1.0.0
```

O ejecútalo en tu terminal:

```bash
dart pub add coouter
```

---

## 🏛️ Los Tres Pilares

Coouter se basa en tres estructuras fundamentales para organizar tu API:

### 1. Handlers (Estilo Funcional)
Ideal para prototipos rápidos o endpoints sencillos.

```dart
final healthCheck = ApiControllerHandler<MyError, JsonResponse>(
  verb: HttpMethod.GET,
  path: '/health',
  handler: (request) async => Right(JsonResponse({'status': 'alive'})),
);
```

### 2. Controladores (Estilo Basado en Clases)
Perfecto para lógica compleja y reutilización. Permite inyectar dependencias y manejar estados.

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
      : Left(AppError.notFound('Usuario no encontrado'));
  };
}
```

### 3. Grupos (Composición)
Agrupa controladores bajo prefijos y middlewares comunes.

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

## 🛡️ Manejo de Errores Tipado

Olvídate de los `try-catch` infinitos. Coouter utiliza `Either` para forzarte a manejar los errores de forma explícita. Define tus fallos extendiendo `ResponseFailure`:

```dart
class AppError extends ResponseFailure {
  const AppError(this.message, {super.statusCode = 500});
  @override
  final String? message;

  factory AppError.notFound(String msg) => AppError(msg, statusCode: 404);
}
```

---

## 📝 Documentación Viva (Swagger)

Añade el mixin `SwaggerInfo` a tus controladores para generar automáticamente la especificación OpenAPI:

```dart
class CreateUserController extends ApiConverterWithBodyController<UserBody, NoParams, AppError, JsonResponse> 
    with SwaggerInfo {
  
  @override
  String get description => 'Crea un nuevo usuario en el sistema';

  @override
  Map<int, ResponseDoc> get responses => {
    201: ResponseDoc('Usuario creado exitosamente', schema: SchemaDoc.name('User')),
    400: ResponseDoc('Datos inválidos'),
  };
}
```

Para servir la documentación, simplemente añade el `SwaggerController`:

```dart
final router = Router()
  ..mount('/api/v1', apiV1.handler)
  ..mount('/docs', SwaggerController(apiRouter: apiV1).handler);
```
Accede a `http://localhost:8080/docs/` y verás tu Swagger UI listo para usar.

---

## 🚀 Ejemplo Completo en 30 Segundos

```dart
import 'package:coouter/coouter.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final api = ApiV1(); // Tu grupo de rutas
  
  final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addHandler(api.handler);

  await shelf_io.serve(handler, '0.0.0.0', 8080);
  print('🚀 Servidor volando en http://localhost:8080');
}
```

---

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Si tienes una idea para una nueva característica o has encontrado un bug, por favor abre un Issue o un Pull Request.

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - mira el archivo [LICENSE](LICENSE) para más detalles.
