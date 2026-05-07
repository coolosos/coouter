import '../../coouter.dart';

/// A concrete implementation of [ApiControllerConverter] that uses a function
/// for its handling logic.
///
/// This class provides a quick, functional way to create a type-safe endpoint
/// without needing to create a new class. It combines the automatic conversion
/// of [ApiControllerConverter] with the functional style of [ApiControllerHandler].
base class ApiConverterWithBodyConverterHandler<
  BODY,
  PARAMS,
  F extends ResponseFailure,
  E extends ResponseEntity
>
    extends ApiConverterWithBodyController<BODY, PARAMS, F, E> {
  ApiConverterWithBodyConverterHandler({
    required super.path,
    required Process<F, E, ApiControllerConverterWithBodyParams<BODY, PARAMS>>
    handler,
    required Mapper<BODY> requestBodyMapper,
    required Mapper<PARAMS> paramsMapper,
    this.requestBodySchema,
    super.verb = HttpMethod.POST,
  }) : _handler = handler,
       _requestBodyMapper = requestBodyMapper,
       _paramsMapper = paramsMapper;

  final Process<F, E, ApiControllerConverterWithBodyParams<BODY, PARAMS>>
  _handler;
  final Mapper<BODY> _requestBodyMapper;
  final Mapper<PARAMS> _paramsMapper;

  @override
  final Map<String, dynamic>? requestBodySchema;

  @override
  Process<F, E, ApiControllerConverterWithBodyParams<BODY, PARAMS>>
  get processConvertedRequest => _handler;

  @override
  Mapper<BODY> get requestBodyMapper => _requestBodyMapper;

  @override
  Mapper<PARAMS> get paramsMapper => _paramsMapper;
}
