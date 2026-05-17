import 'package:clean_forge_cli/src/naming.dart';
import 'package:test/test.dart';

void main() {
  group('naming', () {
    test('converts values to snake case', () {
      expect(toSnakeCase('UserProfile'), 'user_profile');
      expect(toSnakeCase('user-profile'), 'user_profile');
      expect(toSnakeCase('user profile'), 'user_profile');
    });

    test('converts values to pascal case', () {
      expect(toPascalCase('user_profile'), 'UserProfile');
      expect(toPascalCase('user-profile'), 'UserProfile');
      expect(toPascalCase('user profile'), 'UserProfile');
    });
  });
}
