import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:coolson/coolson.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shelf/shelf.dart';
import 'response_entity.dart';
import 'response_failure.dart';

/// Encapsulates the logic of executing a request processing function
/// and converting its result (an Either) into a final HTTP response.
class RequestProcessor<F extends ResponseFailure, T extends ResponseEntity> {
  /// Executes the process and handles the conversion to a [Response].
  Future<Response> execute(Future<Either<F, T>> Function() process) async {
    final result = await process();
    return result.fold(
      (failure) {
        return Response(
          failure.statusCode,
          body: failure.toMap().asJsonStream,
          encoding: Encoding.getByName('utf-8'),
          headers: {
            HttpHeaders.contentTypeHeader: ContentType.json.toString(),
            ...failure.headers,
          },
        );
      },
      (entity) {
        return entity.response;
      },
    );
  }
}
