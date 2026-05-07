import 'package:coouter/coouter.dart';
import 'package:test/test.dart';

final class _DummyEntity extends JsonResponse {
  const _DummyEntity() : super(const {'dummy': true});
}

final class _DummyFailure extends ResponseFailure {
  const _DummyFailure() : super(statusCode: 500);

  @override
  List<Object?> get props => [message, statusCode, headers];
}

ApiControllerHandler<_DummyFailure, _DummyEntity> _makeCtrl() {
  return ApiControllerHandler<_DummyFailure, _DummyEntity>(
    verb: HttpMethod.GET,
    path: '/dummy',
    handler: (_) async => const _DummyEntity(),
    errorHandler: (_, __) async => const _DummyFailure(),
  );
}

void main() {
  group('ApiMountable', () {
    test('single wraps one controller', () {
      final mountable = ApiMountable.single(_makeCtrl());
      expect(mountable.asList.length, 1);
    });

    test('multiple wraps multiple controllers', () {
      final mountable = ApiMountable.multiple([_makeCtrl(), _makeCtrl()]);
      expect(mountable.asList.length, 2);
    });
  });
}
