import 'dart:io';

import 'package:path/path.dart' as p;

import 'config.dart';
import 'errors.dart';
import 'naming.dart';
import 'prompter.dart';

class FeatureResolver {
  FeatureResolver({required this.projectRoot, required this.prompter});

  final Directory projectRoot;
  final Prompter prompter;

  String resolve(CleanConfig config, String? featureName) {
    if (featureName != null && featureName.isNotEmpty) {
      return toSnakeCase(featureName);
    }

    final featuresDirectory = Directory(
      p.join(projectRoot.path, config.path('features')),
    );
    if (!featuresDirectory.existsSync()) {
      throw ForgeException(
        'Missing feature name and no features directory found. '
        'Pass -f <feature_name> or run "forge make:feature <feature_name>".',
      );
    }

    final features =
        featuresDirectory
            .listSync()
            .whereType<Directory>()
            .map((directory) => p.basename(directory.path))
            .where((name) => !name.startsWith('.'))
            .toList()
          ..sort();

    if (features.isEmpty) {
      throw ForgeException(
        'Missing feature name and no existing features found. '
        'Pass -f <feature_name>.',
      );
    }

    final selected = prompter.select(
      'Where do you want to place this file?',
      features,
    );
    return features[selected];
  }
}
