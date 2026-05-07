part of 'base_controller.dart';

/// A controller that groups multiple [BaseController] instances together under
/// the same route prefix.
///
/// This class helps in organizing the main router file by allowing you to
/// combine several controllers into a single logical unit.
abstract class ApiControllers extends BaseController {
  const ApiControllers();

  List<BaseController> get routes;

  @override
  void _buildRouter(Router router) {
    for (final controller in routes) {
      controller._buildRouter(router);
    }
  }

  @override
  Handler get handler {
    final FutureOr<Response> Function(Request request) innerHandler;
    if (routes.isEmpty) {
      innerHandler = notFoundHandler;
    } else {
      var cascade = Cascade();
      for (final controller in routes) {
        cascade = cascade.add(controller.handler);
      }
      innerHandler = cascade.handler;
    }

    if (middlewares.isEmpty) {
      return innerHandler;
    } else {
      var pipeline = const Pipeline();
      for (final mw in middlewares) {
        pipeline = pipeline.addMiddleware(mw.middleware);
      }

      return pipeline.addHandler(innerHandler);
    }
  }
}
