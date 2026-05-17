import 'dart:convert';
import 'dart:io';

import 'package:clean_forge_cli/src/config.dart';
import 'package:clean_forge_cli/src/prompter.dart';
import 'package:clean_forge_cli/src/runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory sandbox;
  late FakePrompter prompter;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('clean_forge_cli_test_');
    prompter = FakePrompter();
  });

  tearDown(() {
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  void writeConfig() {
    const encoder = JsonEncoder.withIndent('  ');
    File(p.join(sandbox.path, 'clean_config.json')).writeAsStringSync(
      '${encoder.convert(CleanConfig.defaultConfig().toJson())}\n',
    );
  }

  test('make:feature creates the default clean architecture folders', () async {
    writeConfig();

    final exitCode = await runCleanForgeCli(
      ['make:feature', 'auth'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    expect(exitCode, 0);
    expect(
      Directory(
        p.join(sandbox.path, 'lib/features/auth/data/datasources'),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        p.join(sandbox.path, 'lib/features/auth/presentation/bloc'),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        p.join(sandbox.path, 'lib/features/auth/presentation/widgets'),
      ).existsSync(),
      isFalse,
    );
  });

  test('make:feature can include presentation widgets folder', () async {
    writeConfig();
    prompter.confirmAnswers.add(true);

    final exitCode = await runCleanForgeCli(
      ['make:feature', 'user'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    expect(exitCode, 0);
    expect(
      Directory(
        p.join(sandbox.path, 'lib/features/user/presentation/widgets'),
      ).existsSync(),
      isTrue,
    );
  });

  test('make:entity renders stubs/entity.stub into domain/entities', () async {
    writeConfig();
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(p.join(stubs.path, 'entity.stub')).writeAsStringSync(
      'class {{ClassName}}Entity {} // {{feature_name}}/{{file_name}}',
    );

    final exitCode = await runCleanForgeCli(
      ['make:entity', 'UserProfile', '-f', 'auth'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    final entityFile = File(
      p.join(
        sandbox.path,
        'lib/features/auth/domain/entities/user_profile.dart',
      ),
    );

    expect(exitCode, 0);
    expect(entityFile.existsSync(), isTrue);
    expect(
      entityFile.readAsStringSync(),
      'class UserProfileEntity {} // auth/user_profile',
    );
  });

  test('make:entity renders custom fields', () async {
    writeConfig();
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(
      p.join(stubs.path, 'entity.stub'),
    ).writeAsStringSync('const factory {{ClassName}}({\n{{fields}}\n});');
    prompter.selectAnswers.add(1);
    prompter.inputLineAnswers.add([
      'String id -r',
      'String alamat -o',
      'int age -o',
    ]);

    final exitCode = await runCleanForgeCli(
      ['make:entity', 'User', '-f', 'user'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    final entityFile = File(
      p.join(sandbox.path, 'lib/features/user/domain/entities/user.dart'),
    );

    expect(exitCode, 0);
    expect(
      entityFile.readAsStringSync(),
      contains('    required String id,\n    String? alamat,\n    int? age,'),
    );
  });

  test('make:entity migrates old default entity stub field line', () async {
    writeConfig();
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(p.join(stubs.path, 'entity.stub')).writeAsStringSync('''
const factory {{ClassName}}({
  required String id,
});
''');
    prompter.selectAnswers.add(1);
    prompter.inputLineAnswers.add(['String id -r', 'String fullName -o']);

    final exitCode = await runCleanForgeCli(
      ['make:entity', 'user_entity/user_entity', '-f', 'user'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    final entityFile = File(
      p.join(
        sandbox.path,
        'lib/features/user/domain/entities/user_entity/user_entity.dart',
      ),
    );

    expect(exitCode, 0);
    expect(
      entityFile.readAsStringSync(),
      contains('required String id,\n    String? fullName,'),
    );
  });

  test(
    'make:entity can generate matching model with snake case keys',
    () async {
      writeConfig();
      final stubs = Directory(p.join(sandbox.path, 'stubs'))
        ..createSync(recursive: true);
      File(p.join(stubs.path, 'entity.stub')).writeAsStringSync('''
const factory {{ClassName}}({
  required String id,
});
''');
      File(p.join(stubs.path, 'model.stub')).writeAsStringSync('''
const factory {{ClassName}}Model({
  required String id,
});
''');
      prompter.selectAnswers.addAll([1, 1]);
      prompter.inputLineAnswers.add(['int id', 'String fullName -o']);
      prompter.confirmAnswers.add(true);

      final exitCode = await runCleanForgeCli(
        ['make:entity', 'user_entity/user_entity', '-f', 'user'],
        projectRoot: sandbox,
        prompter: prompter,
      );

      final modelFile = File(
        p.join(
          sandbox.path,
          'lib/features/user/data/models/user_entity/user_model.dart',
        ),
      );

      expect(exitCode, 0);
      expect(modelFile.existsSync(), isTrue);
      expect(
        modelFile.readAsStringSync(),
        contains(
          '@JsonKey(name: "id") required int id,\n'
          '    @JsonKey(name: "full_name") String? fullName,',
        ),
      );
    },
  );

  test('make:entity can customize matching model keys and defaults', () async {
    writeConfig();
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(p.join(stubs.path, 'entity.stub')).writeAsStringSync('{{fields}}');
    File(p.join(stubs.path, 'model.stub')).writeAsStringSync('{{fields}}');
    prompter.selectAnswers.addAll([1, 2]);
    prompter.inputLineAnswers.add(['bool isActive']);
    prompter.confirmAnswers.add(true);
    prompter.inputAnswers.addAll(['is_active', 'true']);

    final exitCode = await runCleanForgeCli(
      ['make:entity', 'user_entity', '-f', 'user'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    final modelFile = File(
      p.join(sandbox.path, 'lib/features/user/data/models/user_model.dart'),
    );

    expect(exitCode, 0);
    expect(
      modelFile.readAsStringSync().trim(),
      '@JsonKey(name: "is_active") @Default(true) required bool isActive,',
    );
  });

  test('make:model migrates old default model stub field line', () async {
    writeConfig();
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(p.join(stubs.path, 'model.stub')).writeAsStringSync('''
const factory {{ClassName}}Model({
  required String id,
});
''');
    prompter.selectAnswers.add(1);
    prompter.inputLineAnswers.add([
      'String fullName -r --key="full_name"',
      'bool isActive -r --key="is_active" --default=true',
    ]);

    final exitCode = await runCleanForgeCli(
      ['make:model', 'user_model/user_model', '-f', 'user'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    final modelFile = File(
      p.join(
        sandbox.path,
        'lib/features/user/data/models/user_model/user_model.dart',
      ),
    );

    expect(exitCode, 0);
    expect(
      modelFile.readAsStringSync(),
      contains('@JsonKey(name: "full_name") required String fullName,'),
    );
  });

  test('make:entity can choose feature and use nested output path', () async {
    writeConfig();
    Directory(
      p.join(sandbox.path, 'lib/features/user/domain/entities'),
    ).createSync(recursive: true);
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(p.join(stubs.path, 'entity.stub')).writeAsStringSync('{{fields}}');
    prompter.selectAnswers.addAll([0, 0]);

    final exitCode = await runCleanForgeCli(
      ['make:entity', 'user_entity', '/user_entity'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    expect(exitCode, 0);
    expect(
      File(
        p.join(
          sandbox.path,
          'lib/features/user/domain/entities/user_entity/user_entity.dart',
        ),
      ).existsSync(),
      isTrue,
    );
  });

  test('make:entity supports nested path in the entity argument', () async {
    writeConfig();
    Directory(
      p.join(sandbox.path, 'lib/features/user/domain/entities'),
    ).createSync(recursive: true);
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(
      p.join(stubs.path, 'entity.stub'),
    ).writeAsStringSync('class {{ClassName}} {} // {{file_name}}');
    prompter.selectAnswers.addAll([0, 0]);

    final exitCode = await runCleanForgeCli(
      ['make:entity', 'user_entity/user_entity'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    final entityFile = File(
      p.join(
        sandbox.path,
        'lib/features/user/domain/entities/user_entity/user_entity.dart',
      ),
    );

    expect(exitCode, 0);
    expect(entityFile.existsSync(), isTrue);
    expect(entityFile.readAsStringSync(), 'class UserEntity {} // user_entity');
  });

  test('make:model renders JsonKey and Default options', () async {
    writeConfig();
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(
      p.join(stubs.path, 'model.stub'),
    ).writeAsStringSync('const factory {{ClassName}}Model({\n{{fields}}\n});');
    prompter.selectAnswers.add(1);
    prompter.inputLineAnswers.add([
      'String fullName -r --key="full_name"',
      'bool isActive -r --key="is_active" --default=true',
    ]);

    final exitCode = await runCleanForgeCli(
      ['make:model', 'User', '-f', 'user'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    final modelFile = File(
      p.join(sandbox.path, 'lib/features/user/data/models/user.dart'),
    );

    expect(exitCode, 0);
    expect(
      modelFile.readAsStringSync(),
      contains(
        '@JsonKey(name: "full_name") required String fullName,\n'
        '    @JsonKey(name: "is_active") @Default(true) required bool isActive,',
      ),
    );
  });

  test('make:model avoids duplicate Model suffix', () async {
    writeConfig();
    final stubs = Directory(p.join(sandbox.path, 'stubs'))
      ..createSync(recursive: true);
    File(
      p.join(stubs.path, 'model.stub'),
    ).writeAsStringSync('class {{ClassName}}Model {}');

    final exitCode = await runCleanForgeCli(
      ['make:model', 'user_model', '-f', 'user'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    final modelFile = File(
      p.join(sandbox.path, 'lib/features/user/data/models/user_model.dart'),
    );

    expect(exitCode, 0);
    expect(modelFile.readAsStringSync(), 'class UserModel {}');
  });

  test('returns usage exit code when required arguments are missing', () async {
    final exitCode = await runCleanForgeCli(
      ['make:feature'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    expect(exitCode, 64);
  });

  test('returns failure exit code when clean_config.json is missing', () async {
    final exitCode = await runCleanForgeCli(
      ['make:feature', 'auth'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    expect(exitCode, 1);
  });

  test('returns failure exit code when entity stub is missing', () async {
    writeConfig();

    final exitCode = await runCleanForgeCli(
      ['make:entity', 'User', '-f', 'auth'],
      projectRoot: sandbox,
      prompter: prompter,
    );

    expect(exitCode, 1);
  });
}

class FakePrompter implements Prompter {
  final confirmAnswers = <bool>[];
  final inputAnswers = <String>[];
  final inputLineAnswers = <List<String>>[];
  final selectAnswers = <int>[];

  @override
  bool confirm(String message, {bool defaultValue = false}) {
    if (confirmAnswers.isEmpty) {
      return defaultValue;
    }

    return confirmAnswers.removeAt(0);
  }

  @override
  String input(String message, {String? defaultValue}) {
    if (inputAnswers.isEmpty) {
      return defaultValue ?? '';
    }

    return inputAnswers.removeAt(0);
  }

  @override
  List<String> inputLines(String message) {
    if (inputLineAnswers.isEmpty) {
      return const [];
    }

    return inputLineAnswers.removeAt(0);
  }

  @override
  int select(String message, List<String> options) {
    if (selectAnswers.isEmpty) {
      return 0;
    }

    return selectAnswers.removeAt(0);
  }
}
