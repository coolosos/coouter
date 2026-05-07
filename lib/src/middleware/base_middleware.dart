import 'dart:async';
import 'package:shelf/shelf.dart';

/// A base class for creating custom middleware.
///
/// This abstraction simplifies the creation of Shelf middleware by providing a
/// clear structure and handling the boilerplate of the middleware pipeline.
abstract class BaseMiddleware {
  const BaseMiddleware();

  Middleware get middleware => handler;

  Handler handler(Handler innerHandler) =>
      (Request request) => executor(innerHandler, request);

  FutureOr<Response> executor(Handler innerHandler, Request request);

  String? get swaggerDescription => null;
}
