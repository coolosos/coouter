import 'dart:convert';
import 'dart:io';

import 'package:coouter/coouter.dart';
import 'package:coolson/coolson.dart';
import 'package:json_schema/json_schema.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('BadRequestMiddleware', () {
    const middleware = BadRequestMiddleware();

    test('passthrough on success', () async {
      final handler = middleware.handler((_) async => Response.ok('ok'));
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), 'ok');
    });

    test('catches BadConversionException and return s 400', () async {
      final handler = middleware.handler(
        (_) async => throw BadConversionException('invalid'),
      );
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('catches FormatException and return s 400', () async {
      final handler = middleware.handler(
        (_) async => throw FormatException('bad format'),
      );
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test(
      'catches SchemaValidationException and return s 400 with code 2',
      () async {
        final handler = middleware.handler(
          (_) async => throw SchemaValidationException(
            ValidationResults(<ValidationError>[], <ValidationError>[]),
          ),
        );
        final response = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        );

        expect(response.statusCode, HttpStatus.badRequest);
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['code'], 2);
      },
    );
  });
}
