import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../cli_ui.dart';
import '../config.dart';
import '../feature_resolver.dart';
import '../field_definition.dart';
import '../naming.dart';
import '../prompter.dart';
import '../template_engine.dart';

class MakeModelCommand extends Command<int> {
  MakeModelCommand({Directory? projectRoot, Prompter? prompter})
    : projectRoot = projectRoot ?? Directory.current,
      prompter = prompter ?? const InteractPrompter() {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Feature name where the model will be generated.',
      valueHelp: 'feature_name',
    );
  }

  @override
  final String name = 'make:model';

  @override
  final String description = 'Generate a model from stubs/model.stub.';

  final Directory projectRoot;
  final Prompter prompter;

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    final modelInput = rest.isEmpty ? null : rest.first;
    final explicitSubdirectory = rest.length > 1 ? rest[1] : null;
    final featureOption = argResults?['feature'] as String?;

    if (modelInput == null) {
      throw UsageException('Missing required <ModelName>.', usage);
    }

    final target = _resolveTarget(modelInput, explicitSubdirectory);
    final config = ConfigRepository(projectRoot: projectRoot).read();
    final className = stripSuffix(toPascalCase(target.name), 'Model');
    final fileName = toSnakeCase(target.name);
    final featureSnake = FeatureResolver(
      projectRoot: projectRoot,
      prompter: prompter,
    ).resolve(config, featureOption);
    final fieldSelection = _resolveFields();

    final templateEngine = TemplateEngine(projectRoot: projectRoot);
    final template = templateEngine.ensureFieldsPlaceholder(
      templateEngine.readStub('model'),
      stubName: 'model',
      fields: fieldSelection.fields,
      requireFields: fieldSelection.isCustom,
    );
    final output = templateEngine.render(template, {
      'FeatureName': toPascalCase(featureSnake),
      'feature_name': featureSnake,
      'ClassName': className,
      'ModelName': className,
      'file_name': fileName,
      'fields': fieldSelection.fields,
    });

    final baseDirectory = Directory(
      p.join(
        projectRoot.path,
        config.path('features'),
        featureSnake,
        config.path('data'),
        config.path('models'),
      ),
    );
    final targetDirectory = Directory(
      p.join(baseDirectory.path, target.subdirectory),
    )..createSync(recursive: true);

    final targetFile = File(p.join(targetDirectory.path, '$fileName.dart'));
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsStringSync(output);

    CliUi.success('Generated ${p.relative(targetFile.path)}');
    return 0;
  }

  _FieldSelection _resolveFields() {
    final mode = prompter.select('How do you want to define model fields?', [
      'Default - only generate required String id',
      'Custom - define fields manually with JsonKey/Default support',
    ]);
    if (mode == 0) {
      return const _FieldSelection(
        fields: '    required String id,',
        isCustom: false,
      );
    }

    CliUi.box('Custom model fields', [
      'Write one field per line.',
      'Press Enter on an empty line to finish.',
      '',
      'Format:',
      '  type_data nama_variabel [-r|-o] [--key=api_key] [--default=value]',
      '  Missing -r/-o defaults to required.',
      '',
      'Examples:',
      '  String id -r',
      '  String fullName --key="full_name"',
      '  bool isActive -r --key="is_active" --default=true',
    ]);

    final fields = prompter
        .inputLines('Fields')
        .map(
          (input) =>
              FieldDefinitionParser().parse(input, allowModelOptions: true),
        )
        .toList();

    if (fields.isEmpty) {
      return const _FieldSelection(
        fields: '    required String id,',
        isCustom: false,
      );
    }

    return _FieldSelection(
      fields: fields
          .map((field) => '    ${field.renderModelField()}')
          .join('\n'),
      isCustom: true,
    );
  }

  _TargetFile _resolveTarget(String input, String? explicitSubdirectory) {
    final normalizedInput = input.trim().replaceAll('\\', '/');
    final embeddedDirectory = p.posix.dirname(normalizedInput);
    final name = p.posix.basename(normalizedInput);
    final subdirectorySource =
        explicitSubdirectory ??
        (embeddedDirectory == '.' ? null : embeddedDirectory);

    return _TargetFile(
      name: name,
      subdirectory: _normalizeSubdirectory(subdirectorySource),
    );
  }

  String _normalizeSubdirectory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    final normalized = value.trim().replaceAll('\\', '/');
    return p.normalize(normalized.replaceFirst(RegExp(r'^/+'), ''));
  }
}

class _TargetFile {
  const _TargetFile({required this.name, required this.subdirectory});

  final String name;
  final String subdirectory;
}

class _FieldSelection {
  const _FieldSelection({required this.fields, required this.isCustom});

  final String fields;
  final bool isCustom;
}
