import 'dart:io';

import 'package:coouter/coouter.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

final class _EchoProxy extends ProxyController {
  _EchoProxy() : super(path: '/echo');

  @override
  Future<Response> processRequest(Request request) async {
    return Response.ok('echoed');
  }
}

final class _ParamProxy extends ProxyController {
  _ParamProxy() : super(path: '/assets/<path|.*>');

  @override
  Future<Response> processRequest(Request request) async {
    final p = request.params['path'] ?? 'none';
    return Response.ok('asset:$p');
  }
}

void main() {
  group('ProxyController', () {
    test('handles exact path match', () async {
      final controller = _EchoProxy();

      final request = Request('GET', Uri.parse('http://localhost/echo'));
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), 'echoed');
    });

    test('handles wildcard path params', () async {
      final controller = _ParamProxy();

      final request = Request(
        'GET',
        Uri.parse('http://localhost/assets/images/logo.png'),
      );
      final response = await controller.handler(request);

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.readAsString(), 'asset:images/logo.png');
    });

    test('return s 404 on unknown path', () async {
      final controller = _EchoProxy();

      final request = Request('GET', Uri.parse('http://localhost/unknown'));
      final response = await controller.handler(request);

      expect(response.statusCode, 404);
    });
  });
}
