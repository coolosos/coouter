sealed class ProcessConvertParams {
  const ProcessConvertParams();
}

final class ApiControllerConverterParams<PARAMS> extends ProcessConvertParams {
  const ApiControllerConverterParams(this.params);

  final PARAMS params;
}

final class ApiControllerConverterWithBodyParams<BODY, PARAMS>
    extends ProcessConvertParams {
  const ApiControllerConverterWithBodyParams(this.body, this.params);

  final BODY body;
  final PARAMS params;
}
