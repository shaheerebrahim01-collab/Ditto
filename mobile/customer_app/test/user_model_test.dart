import 'package:customer_app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DittoUser.fromJson', () {
    test('parses the shape returned by GET /users/me', () {
      final user = DittoUser.fromJson({
        'id': 'cabc123',
        'email': 'alex@example.com',
        'phone': null,
        'role': 'CUSTOMER',
        'fullName': 'Alex Doe',
        'avatarUrl': null,
        'authProvider': 'google',
      });

      expect(user.id, 'cabc123');
      expect(user.email, 'alex@example.com');
      expect(user.phone, isNull);
      expect(user.role, 'CUSTOMER');
      expect(user.fullName, 'Alex Doe');
      expect(user.authProvider, 'google');
    });

    test('throws when a required field is missing', () {
      expect(
        () => DittoUser.fromJson({'id': 'cabc123'}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
