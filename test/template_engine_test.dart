import 'package:clean_forge_cli/src/template_engine.dart';
import 'package:test/test.dart';

void main() {
  test('replaces known placeholders', () {
    final output = TemplateEngine().render(
      'class {{ClassName}} {} // {{file_name}}',
      {'ClassName': 'User', 'file_name': 'user'},
    );

    expect(output, 'class User {} // user');
  });
}
