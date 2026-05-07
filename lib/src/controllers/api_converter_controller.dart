import 'dart:async';

import 'package:coolson/coolson.dart';
import 'package:coouter/src/controllers/process_convert_params.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shelf/shelf.dart';

import '../core/response_entity.dart';
import '../core/response_failure.dart';
import '../middleware/bad_request_middleware.dart';
import '../middleware/base_middleware.dart';
import 'base_controller.dart';

typedef Process<F, E, C extends ProcessConvertParams> =
    Future<Either<F, E>> Function(C context, Request request);

abstract class ApiConverter<
  PARAMS,
  F extends ResponseFailure,
  E extends ResponseEntity,
  CP extends ProcessConvertParams
>
    extends ApiController<F, E> {
  const ApiConverter({required super.verb, required super.path});

  @override
  List<BaseMiddleware> get middlewares => [
    ...super.middlewares,
    const BadRequestMiddleware(),
  ];

  Process<F, E, CP> get processConvertedRequest;
}

/// An [ApiController] that automatically handles the conversion of request
/// parameters and body into strongly-typed objects.
///
/// This class abstracts away the boilerplate of data parsing and validation,
/// allowing handler logic to focus on business rules with type-safe data.
abstract class ApiConverterController<
  PARAMS,
  F extends ResponseFailure,
  E extends ResponseEntity
>
    extends ApiConverter<PARAMS, F, E, ApiControllerConverterParams<PARAMS>> {
  const ApiConverterController({required super.verb, required super.path});

  Mapper<PARAMS> get paramsMapper;

  @override
  Future<Either<F, E>> processRequest(Request request) async {
    final context = paramsMapper(allParams(request));

    return processConvertedRequest(
      ApiControllerConverterParams(context),
      request,
    );
  }
}
