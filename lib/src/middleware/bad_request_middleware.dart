import 'dart:async';
import 'dart:io';
import 'package:coolson/coolson.dart';
import 'package:shelf/shelf.dart' show Handler, Request, Response;
import 'base_middleware.dart';

/// A middleware that catches [BadRequestException] and converts it into a
/// standardized JSON error response.
///
/// This helps to avoid unhandled exceptions and ensures that errors related to
/// bad request data are communicated to the client in a consistent format.
class BadRequestMiddleware extends BaseMiddleware {
  const BadRequestMiddleware();

  @override
  Future<Response> executor(Handler innerHandler, Request request) async {
    try {
      return await innerHandler(request);
    } on BadConversionException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: {'code': 1, 'message': e.message}.asJsonStream,
        headers: {'Content-Type': 'application/json'},
      );
    } on FormatException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: {'code': 1, 'message': e.message}.asJsonStream,
        headers: {'Content-Type': 'application/json'},
      );
    } on SchemaValidationException catch (e) {
      return Response(
        HttpStatus.badRequest,
        body: {'code': 2, 'message': e.message}.asJsonStream,
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
