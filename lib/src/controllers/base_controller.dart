library;

import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../core/request_processor.dart';
import '../core/response_entity.dart';
import '../core/response_failure.dart';
import '../middleware/base_middleware.dart';
import '../utils/http_method.dart';

export '../swagger_models.dart';

part 'api_controller.dart';
part 'api_controllers.dart';
part 'proxy_controller.dart';

/// An abstract class that defines the core structure of a controller.
///
/// The purpose of a controller is to encapsulate a set of related routes and
/// their handling logic, including any middleware, into a single, reusable unit.
sealed class BaseController {
  const BaseController();

  void _buildRouter(Router router);

  Router get _router {
    final router = Router(notFoundHandler: notFoundHandler);

    _buildRouter(router);
    return router;
  }

  Map<String, String> pathParams(Request request) => request.params;
  Map<String, String> queryParams(Request request) =>
      request.url.queryParameters;
  Map<String, String> allParams(Request request) => request.allParams;

  Response notFoundHandler(Request request) => Router.routeNotFound;

  List<BaseMiddleware> get middlewares => const [];

  Stream<List<int>> body(Request request) => request.read();

  Handler get handler {
    if (middlewares.isEmpty) {
      return _router.call;
    }
    var pipeline = const Pipeline();
    for (final mw in middlewares) {
      pipeline = pipeline.addMiddleware(mw.middleware);
    }
    return pipeline.addHandler(_router.call);
  }
}

extension AllParams on Request {
  Map<String, String> get allParams => {...this.params, ...url.queryParameters};
}
