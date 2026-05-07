part of 'base_controller.dart';

/// An abstract controller for API endpoints that defines a single route.
///
/// This class combines the routing logic of a [BaseController] with the
/// structured request handling of [ProcessRequest], making it the foundation
/// for most API endpoint implementations.
abstract class ApiController<
  F extends ResponseFailure,
  E extends ResponseEntity
>
    extends BaseController {
  const ApiController({required this.verb, required this.path});

  final HttpMethod verb;

  final String path;

  @protected
  RequestProcessor get processor => RequestProcessor<F, E>();

  @protected
  Future<Either<F, E>> processRequest(Request request);

  @override
  void _buildRouter(Router router) {
    router.add(verb.method, path, (Request request) async {
      final response = await processor.execute(() => processRequest(request));
      return response;
    });
  }
}
