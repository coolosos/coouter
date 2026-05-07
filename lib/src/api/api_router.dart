import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../api/api_mountable.dart';
import '../middleware/base_middleware.dart';

/// A controller that mounts other controllers under specific path prefixes.
///
/// This class is the cornerstone of modular routing, allowing you to compose a
/// complex API from smaller, self-contained controller units.
abstract base class ApiRouter {
  const ApiRouter();

  Map<String, ApiMountable> get controllers;
  List<BaseMiddleware> get middlewares => const [];

  // Iterable<BaseMiddleware> _findMiddleware(List<BaseController> controllers) {
  //   return controllers
  //       .map<List<BaseMiddleware>>((e) {
  //         switch (e) {
  //           case ApiController<ResponseFailure, ResponseEntity>():
  //             return e.apiMiddlewares;
  //           case ProxyController():
  //             return e.apiMiddlewares;
  //           case ApiControllers():
  //             return [...e.apiMiddlewares, ..._findMiddleware(e.routes)];
  //         }
  //       })
  //       .expand((element) => element);
  // }

  void _buildRouter(Router router) {
    for (final def in controllers.entries) {
      final key = def.key;
      final value = def.value;

      switch (value) {
        case SingleApi(:final controller):
          router.mount(key, controller.handler);
        case MultipleApis(:final controllers):
          var cascade = Cascade();
          for (final c in controllers) {
            cascade = cascade.add(c.handler);
            // router.mount(key, c.handler);
          }
          router.mount(key, cascade.handler);
      }
    }
  }

  Router get _router {
    final router = Router(notFoundHandler: notFoundHandler);

    _buildRouter(router);
    return router;
  }

  Response notFoundHandler(Request request) => Router.routeNotFound;

  Handler get handler {
    // final apiMiddlewares = <dynamic>{
    //   ...middlewares,
    //   ...controllers.values.map((e) => _findMiddleware(e.asList)),
    // };
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
