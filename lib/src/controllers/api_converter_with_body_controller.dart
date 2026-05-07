import 'dart:async';

import 'package:coolson/coolson.dart';
import 'package:coouter/coouter.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shelf/shelf.dart';

export 'package:coolson/coolson.dart' show Mapper;
export 'package:coouter/src/controllers/process_convert_params.dart'
    show ApiControllerConverterWithBodyParams;

/// An [ApiController] that automatically handles the conversion of request
/// parameters and body into strongly-typed objects.
///
/// This class abstracts away the boilerplate of data parsing and validation,
/// allowing handler logic to focus on business rules with type-safe data.
abstract class ApiConverterWithBodyController<
  BODY,
  PARAMS,
  F extends ResponseFailure,
  E extends ResponseEntity
>
    extends
        ApiConverter<
          PARAMS,
          F,
          E,
          ApiControllerConverterWithBodyParams<BODY, PARAMS>
        > {
  const ApiConverterWithBodyController({
    required super.verb,
    required super.path,
  });

  Mapper<PARAMS> get paramsMapper;

  Mapper<BODY> get requestBodyMapper;
  Map<String, dynamic>? get requestBodySchema => null;

  JsonStreamDecoder get converter {
    if (requestBodySchema case final requestBodySchema?) {
      return SingleJsonDecoder<BODY>(
        requestBodyMapper,
        schema: JsonSchema.create(requestBodySchema),
      );
    }
    return SingleJsonDecoder<BODY>(requestBodyMapper);
  }

  @override
  Future<Either<F, E>> processRequest(Request request) async {
    final context = paramsMapper(allParams(request));
    final bodyDecoded = await converter.convert(
      body(request),
      encoding: request.encoding,
    );

    return processConvertedRequest(
      ApiControllerConverterWithBodyParams(bodyDecoded, context),
      request,
    );
  }
}
