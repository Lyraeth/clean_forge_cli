import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'errors.dart';

class CleanConfig {
  CleanConfig({required this.paths, required this.naming});

  factory CleanConfig.defaultConfig() {
    return CleanConfig(
      paths: const {
        'features': 'lib/features',
        'data': 'data',
        'domain': 'domain',
        'presentation': 'presentation',
        'datasources': 'datasources',
        'models': 'models',
        'repositories': 'repositories',
        'usecases': 'usecases',
        'entities': 'entities',
        'ui': 'pages',
        'state': 'bloc',
      },
      naming: const {'dataClassGenerator': 'freezed'},
    );
  }

  factory CleanConfig.fromJson(Map<String, Object?> json) {
    final paths = json['paths'];
    final naming = json['naming'];

    if (paths is! Map || naming is! Map) {
      throw ForgeException(
        'clean_config.json must contain "paths" and "naming" objects.',
      );
    }

    return CleanConfig(
      paths: paths.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      naming: naming.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }

  final Map<String, String> paths;
  final Map<String, String> naming;

  Map<String, Object?> toJson() => {'paths': paths, 'naming': naming};

  String path(String key) {
    final value = paths[key];
    if (value == null || value.isEmpty) {
      throw ForgeException('Missing "$key" path in clean_config.json.');
    }

    return value;
  }
}

class ConfigRepository {
  ConfigRepository({Directory? projectRoot})
    : projectRoot = projectRoot ?? Directory.current;

  static const fileName = 'clean_config.json';

  final Directory projectRoot;

  File get file => File(p.join(projectRoot.path, fileName));

  CleanConfig read() {
    if (!file.existsSync()) {
      throw ForgeException(
        'Missing clean_config.json. Run "forge init" in your Flutter project '
        'root first.',
      );
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      throw ForgeException('clean_config.json must contain a JSON object.');
    }

    return CleanConfig.fromJson(decoded);
  }

  void write(CleanConfig config, {bool overwrite = false}) {
    if (file.existsSync() && !overwrite) {
      throw ForgeException('clean_config.json already exists.');
    }

    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(config.toJson())}\n');
  }
}
