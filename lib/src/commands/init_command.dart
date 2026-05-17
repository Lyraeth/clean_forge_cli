import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import '../default_stubs.dart';
import '../prompter.dart';

class InitCommand extends Command<int> {
  InitCommand({Directory? projectRoot, Prompter? prompter})
    : projectRoot = projectRoot ?? Directory.current,
      prompter = prompter ?? const InteractPrompter();

  @override
  final String name = 'init';

  @override
  final String description = 'Initialize Clean Forge config and local stubs.';

  final Directory projectRoot;
  final Prompter prompter;

  @override
  Future<int> run() async {
    final setupIndex = prompter.select(
      'Do you want to use the Default setup or Custom setup?',
      const ['Default', 'Custom'],
    );

    final config = switch (setupIndex) {
      0 => CleanConfig.defaultConfig(),
      _ => CleanConfig.defaultConfig(),
    };

    ConfigRepository(projectRoot: projectRoot).write(config);
    _writeDefaultStubs();

    print('Generated clean_config.json and stubs/.');
    if (setupIndex == 1) {
      print('Custom setup will be expanded later; default setup was used.');
    }

    return 0;
  }

  void _writeDefaultStubs() {
    final stubsDirectory = Directory(p.join(projectRoot.path, 'stubs'));
    stubsDirectory.createSync(recursive: true);

    for (final entry in defaultStubs.entries) {
      final file = File(p.join(stubsDirectory.path, '${entry.key}.stub'));
      if (!file.existsSync()) {
        file.writeAsStringSync(entry.value);
      }
    }
  }
}
