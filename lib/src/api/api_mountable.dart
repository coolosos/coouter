import '../controllers/base_controller.dart';

/// A factory that provides a declarative way to group controllers for use
/// with an [ApiRouter].
///
/// This class exists to provide a clean and readable API for defining whether
/// a route prefix should mount a single API source or a list of them.
sealed class ApiMountable {
  const ApiMountable();

  static ApiMountable single(BaseController controller) =>
      SingleApi(controller);

  static ApiMountable multiple(List<BaseController> controllers) =>
      MultipleApis(controllers);

  List<BaseController> get asList;
}

class SingleApi extends ApiMountable {
  const SingleApi(this.controller);

  final BaseController controller;

  @override
  List<BaseController> get asList => [controller];
}

class MultipleApis extends ApiMountable {
  const MultipleApis(this.controllers);

  final List<BaseController> controllers;

  @override
  List<BaseController> get asList => controllers;
}
