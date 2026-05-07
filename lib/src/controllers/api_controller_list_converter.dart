import 'dart:async';

import 'package:coolson/coolson.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shelf/shelf.dart';

import '../core/response_entity.dart';
import '../core/response_failure.dart';
import '../middleware/bad_request_middleware.dart';
import '../middleware/base_middleware.dart';
import 'base_controller.dart';

/// An [ApiController] that automatically handles the conversion of a request
/// body containing a JSON array into a strongly-typed [List] of objects.
///
/// This class is a specialized version of [ApiControllerConverter] for endpoints
/// that expect a list of items, such as bulk creation endpoints.
abstract class ApiControllerListConverter<
  BODY,
  PARAMS,
  F extends ResponseFailure,
  T extends ResponseEntity
>
    extends ApiController<F, T> {
  ApiControllerListConverter({required super.verb, required super.path});

  BODY bodyFromMap(Map<String, dynamic> data);
  PARAMS paramsFromMap(Map<String, dynamic> data);

  ///si se define un bodySchema se utiliza para validar el body
  Map<String, dynamic>? get bodySchema => null;

  JsonStreamDecoder get converter {
    if (bodySchema case final bodySchema?) {
      return ListJsonDecoder<BODY>(
        bodyFromMap,
        schema: JsonSchema.create(bodySchema),
      );
    }
    return ListJsonDecoder<BODY>(bodyFromMap);
  }

  @override
  Future<Either<F, T>> processRequest(Request request) async {
    final params = paramsFromMap(allParams(request));
    final body = await converter.convert(
      request.read(),
      encoding: request.encoding,
    );

    return processConvertedRequest(request, body, params);
  }

  @override
  List<BaseMiddleware> get middlewares => [
    ...super.middlewares,
    //first response
    const BadRequestMiddleware(),
  ];
  Future<Either<F, T>> processConvertedRequest(
    Request request,
    List<BODY> body,
    PARAMS params,
  );
}
