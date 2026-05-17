import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/init_command.dart';
import 'commands/make_entity_command.dart';
import 'commands/make_feature_command.dart';
import 'commands/make_model_command.dart';
import 'errors.dart';
import 'prompter.dart';

const version = '0.0.1';

CommandRunner<int> buildRunner({Directory? projectRoot, Prompter? prompter}) {
  return CommandRunner<int>(
      'forge',
      'Generate Flutter Clean Architecture boilerplate.',
    )
    ..argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the tool version.',
    )
    ..addCommand(InitCommand(projectRoot: projectRoot, prompter: prompter))
    ..addCommand(
      MakeFeatureCommand(projectRoot: projectRoot, prompter: prompter),
    )
    ..addCommand(
      MakeEntityCommand(projectRoot: projectRoot, prompter: prompter),
    )
    ..addCommand(
      MakeModelCommand(projectRoot: projectRoot, prompter: prompter),
    );
}

Future<int> runCleanForgeCli(
  List<String> arguments, {
  Directory? projectRoot,
  Prompter? prompter,
}) async {
  if (arguments.contains('--version')) {
    print('clean_forge_cli version: $version');
    return 0;
  }

  final runner = buildRunner(projectRoot: projectRoot, prompter: prompter);
  try {
    return await runner.run(arguments) ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('');
    stderr.writeln(error.usage);
    return 64;
  } on ForgeException catch (error) {
    stderr.writeln(error.message);
    return 1;
  } on FileSystemException catch (error) {
    stderr.writeln('File system error: ${error.message}');
    if (error.path != null) {
      stderr.writeln(error.path);
    }
    return 1;
  } catch (error) {
    stderr.writeln('Unexpected error: $error');
    return 1;
  }
}
