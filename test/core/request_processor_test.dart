import 'dart:convert';
import 'dart:io';

import 'package:coouter/src/core/request_processor.dart';
import 'package:coouter/src/core/response_entity.dart';
import 'package:coouter/src/core/response_failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';

final class TestEntity extends JsonResponse {
  const TestEntity() : super(const {'ok': true});
}

final class TestFailure extends ResponseFailure {
  const TestFailure({required super.statusCode, super.message, super.headers});

  @override
  List<Object?> get props => [message, statusCode, headers];
}

void main() {
  group('request_processor', () {
    late RequestProcessor<TestFailure, TestEntity> processor;

    setUp(() {
      processor = RequestProcessor<TestFailure, TestEntity>();
    });

    test('execute return s 200 with JSON body on Right', () async {
      final response = await processor.execute(
        () async => const Right(TestEntity()),
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        ContentType.json.value,
      );
      final body = jsonDecode(await response.readAsString());
      expect(body, {'ok': true});
    });

    test('execute return s failure status code on Left', () async {
      final response = await processor.execute(
        () async =>
            const Left(TestFailure(statusCode: 404, message: 'Not Found')),
      );
      expect(response.statusCode, 404);
      final body = jsonDecode(await response.readAsString());
      expect(body['message'], 'Not Found');
    });

    test('execute includes failure headers in response', () async {
      final response = await processor.execute(
        () async => const Left(
          TestFailure(statusCode: 400, headers: {'X-Custom': 'val'}),
        ),
      );
      expect(response.headers['x-custom'], 'val');
    });

    test('execute sets Content-Type to application/json on failure', () async {
      final response = await processor.execute(
        () async => const Left(TestFailure(statusCode: 500)),
      );
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        ContentType.json.toString(),
      );
    });
  });
}
