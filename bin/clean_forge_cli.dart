import 'dart:io';

import 'package:clean_forge_cli/src/runner.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runCleanForgeCli(arguments);
}
