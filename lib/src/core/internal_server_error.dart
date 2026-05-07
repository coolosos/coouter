import 'dart:io';
import 'response_failure.dart';

final class InternalServerError extends ResponseFailure {
  const InternalServerError({
    super.statusCode = HttpStatus.internalServerError,
  });
}
