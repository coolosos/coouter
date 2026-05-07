import 'package:equatable/equatable.dart';

import '../swagger_models.dart';

const errorSchema = SchemaDoc('Error', {r'$ref': 'Error'});

/// A base class for standardizing API error responses.
///
/// This abstraction exists to ensure that all error responses from the API
/// have a consistent and predictable structure, which simplifies client-side
/// error handling.
abstract base class ResponseFailure extends Equatable {
  const ResponseFailure({
    required this.statusCode,
    this.message,
    this.headers = const {},
  });

  final String? message;
  final Map<String, Object> headers;
  final int statusCode;

  Map<String, dynamic> toMap() {
    return {
      'code': message?.hashCode ?? statusCode,
      'message': message ?? 'empty',
    };
  }

  @override
  List<Object?> get props => [message, statusCode, headers];

  @override
  bool? get stringify => true;
}

extension SwaggerResponseDoc on ResponseFailure {
  ResponseDoc get responseDoc =>
      ResponseDoc(message.toString(), schema: errorSchema);
}
