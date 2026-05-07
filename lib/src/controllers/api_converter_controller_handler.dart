import '../../coouter.dart';

/// A concrete implementation of [ApiControllerConverter] that uses a function
/// for its handling logic.
///
/// This class provides a quick, functional way to create a type-safe endpoint
/// without needing to create a new class. It combines the automatic conversion
/// of [ApiControllerConverter] with the functional style of [ApiControllerHandler].
base class ApiConverterControllerHandler<
  BODY,
  PARAMS,
  F extends ResponseFailure,
  E extends ResponseEntity
>
    extends ApiConverterController<PARAMS, F, E> {
  ApiConverterControllerHandler({
    required super.path,
    required Process<F, E, ApiControllerConverterParams<PARAMS>> handler,
    required Mapper<PARAMS> paramsMapper,
    super.verb = HttpMethod.POST,
  }) : _handler = handler,
       _paramsMapper = paramsMapper;

  final Process<F, E, ApiControllerConverterParams<PARAMS>> _handler;
  final Mapper<PARAMS> _paramsMapper;

  @override
  Process<F, E, ApiControllerConverterParams<PARAMS>>
  get processConvertedRequest => _handler;

  @override
  Mapper<PARAMS> get paramsMapper => _paramsMapper;
}
