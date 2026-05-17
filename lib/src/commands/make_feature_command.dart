import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../cli_ui.dart';
import '../config.dart';
import '../naming.dart';
import '../prompter.dart';

class MakeFeatureCommand extends Command<int> {
  MakeFeatureCommand({Directory? projectRoot, Prompter? prompter})
    : projectRoot = projectRoot ?? Directory.current,
      prompter = prompter ?? const InteractPrompter();

  @override
  final String name = 'make:feature';

  @override
  final String description = 'Generate a Clean Architecture feature skeleton.';

  final Directory projectRoot;
  final Prompter prompter;

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      throw UsageException('Missing required <feature_name>.', usage);
    }
    final featureName = rest.first;

    final config = ConfigRepository(projectRoot: projectRoot).read();
    final featurePath = p.join(
      projectRoot.path,
      config.path('features'),
      toSnakeCase(featureName),
    );

    final directories = [
      [config.path('data'), config.path('datasources')],
      [config.path('data'), config.path('models')],
      [config.path('data'), config.path('repositories')],
      [config.path('domain'), config.path('entities')],
      [config.path('domain'), config.path('repositories')],
      [config.path('domain'), config.path('usecases')],
      [config.path('presentation'), config.path('ui')],
      [config.path('presentation'), config.path('state')],
    ];

    final includeWidgets = prompter.confirm(
      'Do you want to add a presentation/widgets folder?',
    );
    if (includeWidgets) {
      directories.add([config.path('presentation'), 'widgets']);
    }

    for (final segments in directories) {
      Directory(
        p.joinAll([featurePath, ...segments]),
      ).createSync(recursive: true);
    }

    CliUi.success('Generated feature skeleton at ${p.relative(featurePath)}');
    return 0;
  }
}
