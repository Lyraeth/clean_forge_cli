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

class MakeEntityCommand extends Command<int> {
  MakeEntityCommand({Directory? projectRoot, Prompter? prompter})
    : projectRoot = projectRoot ?? Directory.current,
      prompter = prompter ?? const InteractPrompter() {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Feature name where the entity will be generated.',
      valueHelp: 'feature_name',
    );
  }

  @override
  final String name = 'make:entity';

  @override
  final String description = 'Generate an entity from stubs/entity.stub.';

  final Directory projectRoot;
  final Prompter prompter;

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    final entityInput = rest.isEmpty ? null : rest.first;
    final explicitSubdirectory = rest.length > 1 ? rest[1] : null;
    final featureOption = argResults?['feature'] as String?;

    if (entityInput == null) {
      throw UsageException('Missing required <EntityName>.', usage);
    }

    final target = _resolveTarget(entityInput, explicitSubdirectory);
    final config = ConfigRepository(projectRoot: projectRoot).read();
    final className = toPascalCase(target.name);
    final fileName = toSnakeCase(target.name);
    final featureSnake = FeatureResolver(
      projectRoot: projectRoot,
      prompter: prompter,
    ).resolve(config, featureOption);
    final fieldSelection = _resolveFields();

    final templateEngine = TemplateEngine(projectRoot: projectRoot);
    final template = templateEngine.ensureFieldsPlaceholder(
      templateEngine.readStub('entity'),
      stubName: 'entity',
      fields: fieldSelection.fields,
      requireFields: fieldSelection.isCustom,
    );
    final output = templateEngine.render(template, {
      'FeatureName': toPascalCase(featureSnake),
      'feature_name': featureSnake,
      'ClassName': className,
      'EntityName': className,
      'file_name': fileName,
      'fields': fieldSelection.fields,
    });

    final baseDirectory = Directory(
      p.join(
        projectRoot.path,
        config.path('features'),
        featureSnake,
        config.path('domain'),
        config.path('entities'),
      ),
    );
    final targetDirectory = Directory(
      p.join(baseDirectory.path, target.subdirectory),
    )..createSync(recursive: true);

    final targetFile = File(p.join(targetDirectory.path, '$fileName.dart'));
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsStringSync(output);

    CliUi.success('Generated ${p.relative(targetFile.path)}');
    _maybeGenerateModel(
      config: config,
      featureName: featureSnake,
      target: target,
      entityClassName: className,
      fields: fieldSelection.definitions,
    );
    return 0;
  }

  _FieldSelection _resolveFields() {
    final mode = prompter.select('How do you want to define entity fields?', [
      'Default - only generate required String id',
      'Custom - define fields manually',
    ]);
    if (mode == 0) {
      return const _FieldSelection(
        fields: '    required String id,',
        isCustom: false,
        definitions: [
          FieldDefinition(type: 'String', name: 'id', isRequired: true),
        ],
      );
    }

    CliUi.box('Custom entity fields', [
      'Write one field per line.',
      'Press Enter on an empty line to finish.',
      '',
      'Format:',
      '  type_data nama_variabel [-r|-o]',
      '  Missing -r/-o defaults to required.',
      '',
      'Examples:',
      '  int id -r',
      '  String name',
      '  String fullName -o',
    ]);

    final fields = prompter
        .inputLines('Fields')
        .map(
          (input) =>
              FieldDefinitionParser().parse(input, allowModelOptions: false),
        )
        .toList();

    if (fields.isEmpty) {
      return const _FieldSelection(
        fields: '    required String id,',
        isCustom: false,
        definitions: [
          FieldDefinition(type: 'String', name: 'id', isRequired: true),
        ],
      );
    }

    return _FieldSelection(
      fields: fields
          .map((field) => '    ${field.renderEntityField()}')
          .join('\n'),
      isCustom: true,
      definitions: fields,
    );
  }

  void _maybeGenerateModel({
    required CleanConfig config,
    required String featureName,
    required _TargetFile target,
    required String entityClassName,
    required List<FieldDefinition> fields,
  }) {
    final shouldGenerate = prompter.confirm(
      'Generate matching model from these entity fields?',
    );
    if (!shouldGenerate) {
      return;
    }

    final modelFields = _resolveModelFields(fields);
    final modelFileName = _modelFileNameFromEntity(target.name);
    final modelClassName = stripSuffix(entityClassName, 'Entity');
    final renderedFields = modelFields
        .map((field) => '    ${field.renderModelField()}')
        .join('\n');

    final templateEngine = TemplateEngine(projectRoot: projectRoot);
    final template = templateEngine.ensureFieldsPlaceholder(
      templateEngine.readStub('model'),
      stubName: 'model',
      fields: renderedFields,
      requireFields: true,
    );
    final output = templateEngine.render(template, {
      'FeatureName': toPascalCase(featureName),
      'feature_name': featureName,
      'ClassName': modelClassName,
      'ModelName': modelClassName,
      'file_name': modelFileName,
      'fields': renderedFields,
    });

    final targetDirectory = Directory(
      p.join(
        projectRoot.path,
        config.path('features'),
        featureName,
        config.path('data'),
        config.path('models'),
        target.subdirectory,
      ),
    )..createSync(recursive: true);
    final targetFile = File(
      p.join(targetDirectory.path, '$modelFileName.dart'),
    );
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsStringSync(output);

    CliUi.success('Generated ${p.relative(targetFile.path)}');
  }

  List<FieldDefinition> _resolveModelFields(List<FieldDefinition> fields) {
    final mode = prompter.select('How do you want model JSON keys?', [
      'No JsonKey annotations',
      'Use snake_case JsonKey for all fields',
      'Customize JsonKey/default per field',
    ]);

    return switch (mode) {
      0 => fields,
      1 =>
        fields
            .map((field) => field.copyWith(jsonKey: toSnakeCase(field.name)))
            .toList(),
      _ => fields.map(_customizeModelField).toList(),
    };
  }

  FieldDefinition _customizeModelField(FieldDefinition field) {
    final jsonKey = prompter.input(
      'JsonKey for ${field.name} (empty for none)',
      defaultValue: toSnakeCase(field.name),
    );
    final defaultValue = prompter.input(
      'Default value for ${field.name} (empty for none)',
    );

    return field.copyWith(
      jsonKey: jsonKey.trim().isEmpty ? null : jsonKey.trim(),
      defaultValue: defaultValue.trim().isEmpty ? null : defaultValue.trim(),
    );
  }

  String _modelFileNameFromEntity(String entityName) {
    final snake = toSnakeCase(entityName);
    final base = snake.endsWith('_entity')
        ? snake.substring(0, snake.length - '_entity'.length)
        : snake;

    return '${base}_model';
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
  const _FieldSelection({
    required this.fields,
    required this.isCustom,
    required this.definitions,
  });

  final String fields;
  final bool isCustom;
  final List<FieldDefinition> definitions;
}
