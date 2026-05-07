import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:shelf/shelf.dart';
import '../core/response_entity.dart';
import '../core/response_failure.dart';
import 'base_controller.dart';

/// A concrete implementation of [ApiController] that uses functions for its
/// handling logic.
///
/// This class allows for a more functional approach to defining controllers,
/// where the request and error handling logic are provided as separate function
/// callbacks instead of through class inheritance.
final class ApiControllerHandler<
  F extends ResponseFailure,
  T extends ResponseEntity
>
    extends ApiController<F, T> {
  ApiControllerHandler({
    required super.verb,
    required super.path,
    required Future<T> Function(Request request) handler,
    required Future<F> Function(Object error, StackTrace stackTrace)
    errorHandler,
  }) : _handler = handler,
       _errorHandler = errorHandler;

  final Future<T> Function(Request request) _handler;
  final Future<F> Function(Object error, StackTrace stackTrace) _errorHandler;

  @override
  Future<Either<F, T>> processRequest(Request request) async {
    try {
      return Right(await _handler(request));
    } catch (e, s) {
      return Left(await _errorHandler(e, s));
    }
  }
}
