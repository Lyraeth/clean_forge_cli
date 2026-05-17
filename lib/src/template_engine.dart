import 'dart:io';

import 'package:path/path.dart' as p;

import 'errors.dart';

class TemplateEngine {
  TemplateEngine({Directory? projectRoot})
    : projectRoot = projectRoot ?? Directory.current;

  final Directory projectRoot;

  String readStub(String stubName) {
    final stub = File(p.join(projectRoot.path, 'stubs', '$stubName.stub'));
    if (!stub.existsSync()) {
      throw ForgeException(
        'Missing stubs/$stubName.stub. Run "forge init" or add the stub file.',
      );
    }

    return stub.readAsStringSync();
  }

  String renderStub(String stubName, Map<String, String> values) {
    return render(readStub(stubName), values);
  }

  String ensureFieldsPlaceholder(
    String template, {
    required String stubName,
    required String fields,
    required bool requireFields,
  }) {
    if (!requireFields) {
      return template;
    }
    if (template.contains('{{fields}}')) {
      return template;
    }

    final migrated = template.replaceFirst(
      RegExp(r'^([ \t]*)required String id,\s*$', multiLine: true),
      fields,
    );
    if (migrated == template) {
      throw ForgeException(
        'stubs/$stubName.stub is missing the {{fields}} placeholder. '
        'Add {{fields}} inside the factory parameter block.',
      );
    }

    return migrated;
  }

  String render(String template, Map<String, String> values) {
    var output = template;
    for (final entry in values.entries) {
      output = output.replaceAll('{{${entry.key}}}', entry.value);
    }

    return output;
  }
}
