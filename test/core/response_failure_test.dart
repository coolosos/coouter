import 'dart:io';

import 'package:coouter/src/core/internal_server_error.dart';
import 'package:coouter/src/core/response_failure.dart';
import 'package:test/test.dart';

final class TestFailure extends ResponseFailure {
  const TestFailure({required super.statusCode, super.message, super.headers});

  @override
  List<Object?> get props => [message, statusCode, headers];
}

void main() {
  group('ResponseFailure', () {
    test('toMap returns code and message', () {
      const failure = TestFailure(statusCode: 404, message: 'Not Found');
      final map = failure.toMap();
      expect(map['code'], isA<int>());
      expect(map['message'], 'Not Found');
    });

    test('toMap uses statusCode as code when message is null', () {
      const failure = TestFailure(statusCode: 418);
      final map = failure.toMap();
      expect(map['code'], 418);
      expect(map['message'], 'empty');
    });

    test('headers are included in props', () {
      const failure = TestFailure(
        statusCode: 400,
        headers: {'X-Custom': 'value'},
      );
      expect(failure.props[2], {'X-Custom': 'value'});
    });

    test('stringify returns true', () {
      const failure = TestFailure(statusCode: 500);
      expect(failure.stringify, isTrue);
    });
  });

  group('SwaggerResponseDoc extension', () {
    test('return s a ResponseDoc from a failure', () {
      const failure = TestFailure(statusCode: 404, message: 'Not Found');
      final doc = failure.responseDoc;
      expect(doc.description, 'Not Found');
      expect(doc.schema, isNotNull);
    });

    test('return s a ResponseDoc with error schema', () {
      const failure = TestFailure(statusCode: 500);
      final doc = failure.responseDoc;
      expect(doc.schema?.name, 'Error');
      expect(doc.schema?.schema, {r'$ref': 'Error'});
    });
  });

  group('InternalServerError', () {
    test('default statusCode is 500', () {
      const error = InternalServerError();
      expect(error.statusCode, HttpStatus.internalServerError);
    });

    test('can override statusCode', () {
      const error = InternalServerError(statusCode: 503);
      expect(error.statusCode, 503);
    });

    test('toMap returns expected structure', () {
      const error = InternalServerError();
      final map = error.toMap();
      expect(map['message'], 'empty');
    });
  });
}
