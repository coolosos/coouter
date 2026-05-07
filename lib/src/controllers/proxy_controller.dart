part of 'base_controller.dart';

/// A controller that forwards all requests under a given path to a single
/// processing method.
///
/// This is useful for creating a catch-all route or for implementing custom
/// routing logic within a single class instead of across multiple controllers.
abstract class ProxyController extends BaseController {
  const ProxyController({required this.path});

  final String path;
  @override
  void _buildRouter(Router router) {
    router.all(path, (Request request) async {
      final response = await processRequest(request);

      return response;
    });
  }

  Future<Response> processRequest(Request request);
}
