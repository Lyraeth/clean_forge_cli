import 'dart:io';

import 'package:interact/interact.dart';

import 'cli_ui.dart';

abstract interface class Prompter {
  bool confirm(String message, {bool defaultValue = false});

  String input(String message, {String? defaultValue});

  List<String> inputLines(String message);

  int select(String message, List<String> options);
}

class InteractPrompter implements Prompter {
  const InteractPrompter();

  @override
  bool confirm(String message, {bool defaultValue = false}) {
    return Confirm(prompt: message, defaultValue: defaultValue).interact();
  }

  @override
  String input(String message, {String? defaultValue}) {
    return Input(prompt: message, defaultValue: defaultValue).interact();
  }

  @override
  List<String> inputLines(String message) {
    stdout.writeln(message);
    final lines = <String>[];
    while (true) {
      stdout.write('> ');
      final line = stdin.readLineSync();
      if (line == null || line.trim().isEmpty) {
        break;
      }
      lines.add(line);
    }

    return lines;
  }

  @override
  int select(String message, List<String> options) {
    return Select(prompt: message, options: options).interact();
  }

  void helpBox(String title, List<String> lines) {
    CliUi.box(title, lines);
  }
}
