import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coouter/src/core/response_entity.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  group('FileResponse', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    test('constructor should assign data and mimeType', () {
      final data = Uint8List.fromList([1, 2, 3]);
      const mimeType = 'application/pdf';
      final fileResponse = FileResponse(data: data, mimeType: mimeType);

      expect(fileResponse.data, equals(data));
      // Internally it's _mimeType, can't access it directly.
      // But I can check it via the response headers.
      expect(
        fileResponse.response.headers[HttpHeaders.contentTypeHeader],
        equals(mimeType),
      );
    });

    test(
      'fromFile should create a FileResponse with file content and mimeType',
      () async {
        final file = fs.file('test.txt')..writeAsStringSync('hello world');
        final fileResponse = await FileResponse.fromFile(file: file);

        final expectedBytes = await file.readAsBytes();
        expect(fileResponse.data, equals(expectedBytes));
        expect(
          fileResponse.response.headers[HttpHeaders.contentTypeHeader],
          'text/plain', // from lookupMimeType
        );
      },
    );

    test('fromFile should use provided contentType', () async {
      final file = fs.file('test.json')..writeAsStringSync('{}');
      final fileResponse = await FileResponse.fromFile(
        file: file,
        contentType: 'application/json',
      );

      final expectedBytes = await file.readAsBytes();
      expect(fileResponse.data, equals(expectedBytes));
      expect(
        fileResponse.response.headers[HttpHeaders.contentTypeHeader],
        ContentType.json.value,
      );
    });

    test('response getter should return a correct Response object', () async {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      const mimeType = 'image/png';
      final fileResponse = FileResponse(data: data, mimeType: mimeType);

      final response = fileResponse.response;

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers[HttpHeaders.contentTypeHeader], equals(mimeType));
      expect(
        response.headers[HttpHeaders.contentLengthHeader],
        equals(data.length.toString()),
      );

      final body = await response.read().toList();
      expect(body, equals([data]));
    });
  });

  group('ContentResponse', () {
    test('response getter returns correct Response object', () async {
      const content = 'hello world';
      final contentType = ContentType.text;
      final contentResponse = ContentResponse(
        content: content,
        contentType: contentType,
      );

      final response = contentResponse.response;

      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        contentType.value,
      );
      expect(await response.readAsString(), content);
    });
  });

  group('JsonResponse', () {
    test('response getter returns correct JSON Response', () async {
      final body = {'key': 'value'};
      final jsonResponse = JsonResponse(body);

      final response = jsonResponse.response;

      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        ContentType.json.value,
      );
      expect(jsonDecode(await response.readAsString()), body);
    });

    test('response getter includes custom headers', () {
      final body = {'key': 'value'};
      final headers = {'x-custom-header': 'custom-value'};
      final jsonResponse = JsonResponse(body, headers: headers);

      final response = jsonResponse.response;

      expect(response.headers['x-custom-header'], 'custom-value');
    });

    test('response handles list header values', () {
      final body = {'key': 'value'};
      final headers = {
        'x-list-header': ['a', 'b', 'c'],
      };
      final jsonResponse = JsonResponse(body, headers: headers);

      final response = jsonResponse.response;

      final headerValue = response.headers['x-list-header'];
      if (headerValue is List) {
        expect(headerValue, ['a', 'b', 'c']);
      } else {
        expect(headerValue, 'a,b,c');
      }
    });

    test('response skips null header values', () {
      final body = {'key': 'value'};
      final headers = <String, dynamic>{'x-null-header': null};
      final jsonResponse = JsonResponse(body, headers: headers);

      final response = jsonResponse.response;

      expect(response.headers.containsKey('x-null-header'), isFalse);
    });

    test('response converts non-string header value to string', () {
      final body = {'key': 'value'};
      final headers = <String, dynamic>{'x-int-header': 42};
      final jsonResponse = JsonResponse(body, headers: headers);

      final response = jsonResponse.response;

      expect(response.headers['x-int-header'], '42');
    });

    test('props returns [body]', () {
      final body = {'key': 'value'};
      final jsonResponse = JsonResponse(body);
      expect(jsonResponse.props, [body]);
    });
  });

  group('EmptyResponse', () {
    test('response getter returns empty 200 OK response', () async {
      const emptyResponse = EmptyResponse();
      final response = emptyResponse.response;

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), isEmpty);
    });

    test('response getter includes custom headers', () {
      const headers = {'x-custom-header': 'custom-value'};
      const emptyResponse = EmptyResponse(headers: headers);

      final response = emptyResponse.response;

      expect(response.headers['x-custom-header'], 'custom-value');
    });

    test('response handles list header values', () {
      final headers = {
        'x-list-header': ['a', 'b', 'c'],
      };
      final emptyResponse = EmptyResponse(headers: headers);

      final response = emptyResponse.response;

      final headerValue = response.headers['x-list-header'];
      if (headerValue is List) {
        expect(headerValue, ['a', 'b', 'c']);
      } else {
        expect(headerValue, 'a,b,c');
      }
    });

    test('props returns empty list', () {
      const emptyResponse = EmptyResponse();
      expect(emptyResponse.props, isEmpty);
    });
  });
}
