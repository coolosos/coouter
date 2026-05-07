import 'package:coouter/coouter.dart';
import 'package:test/test.dart';

void main() {
  group('HttpMethod', () {
    test('GET has correct method string', () {
      expect(HttpMethod.GET.method, 'GET');
    });

    test('POST has correct method string', () {
      expect(HttpMethod.POST.method, 'POST');
    });

    test('PUT has correct method string', () {
      expect(HttpMethod.PUT.method, 'PUT');
    });

    test('DELETE has correct method string', () {
      expect(HttpMethod.DELETE.method, 'DELETE');
    });

    test('PATCH has correct method string', () {
      expect(HttpMethod.PATCH.method, 'PATCH');
    });

    test('HEAD has correct method string', () {
      expect(HttpMethod.HEAD.method, 'HEAD');
    });

    test('all values are uppercase', () {
      for (final v in HttpMethod.values) {
        expect(v.method, equals(v.name));
      }
    });
  });
}
