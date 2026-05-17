import 'package:clean_forge_cli/src/field_definition.dart';
import 'package:test/test.dart';

void main() {
  group('FieldDefinitionParser', () {
    test('defaults missing requiredness flag to required', () {
      final field = FieldDefinitionParser().parse(
        'String name',
        allowModelOptions: false,
      );

      expect(field.renderEntityField(), 'required String name,');
    });

    test('keeps optional flag support', () {
      final field = FieldDefinitionParser().parse(
        'String fullName -o',
        allowModelOptions: false,
      );

      expect(field.renderEntityField(), 'String? fullName,');
    });

    test('supports model JsonKey without requiredness flag', () {
      final field = FieldDefinitionParser().parse(
        'String fullName --key="full_name"',
        allowModelOptions: true,
      );

      expect(
        field.renderModelField(),
        '@JsonKey(name: "full_name") required String fullName,',
      );
    });
  });
}
