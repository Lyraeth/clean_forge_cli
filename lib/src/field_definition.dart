import 'errors.dart';

class FieldDefinition {
  const FieldDefinition({
    required this.type,
    required this.name,
    required this.isRequired,
    this.jsonKey,
    this.defaultValue,
  });

  final String type;
  final String name;
  final bool isRequired;
  final String? jsonKey;
  final String? defaultValue;

  FieldDefinition copyWith({String? jsonKey, String? defaultValue}) {
    return FieldDefinition(
      type: type,
      name: name,
      isRequired: isRequired,
      jsonKey: jsonKey ?? this.jsonKey,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  String renderEntityField() {
    final prefix = isRequired ? 'required ' : '';
    final nullableSuffix = isRequired ? '' : '?';

    return '$prefix$type$nullableSuffix $name,';
  }

  String renderModelField() {
    final annotations = <String>[];
    if (jsonKey != null && jsonKey!.isNotEmpty) {
      annotations.add('@JsonKey(name: "$jsonKey")');
    }
    if (defaultValue != null && defaultValue!.isNotEmpty) {
      annotations.add('@Default($defaultValue)');
    }

    final field = renderEntityField();
    if (annotations.isEmpty) {
      return field;
    }

    return '${annotations.join(' ')} $field';
  }
}

class FieldDefinitionParser {
  FieldDefinition parse(String input, {required bool allowModelOptions}) {
    final tokens = _tokenize(input);
    if (tokens.length < 2) {
      throw ForgeException(
        'Invalid field "$input". Use: type_data nama_variabel [-r|-o]',
      );
    }

    final type = tokens[0];
    final name = tokens[1];
    var isRequired = true;
    String? jsonKey;
    String? defaultValue;

    for (final token in tokens.skip(2)) {
      switch (token) {
        case '-r':
          isRequired = true;
        case '-o':
          isRequired = false;
        default:
          if (token.startsWith('--key=')) {
            if (!allowModelOptions) {
              throw ForgeException('--key is only supported for make:model.');
            }
            jsonKey = _optionValue(token, '--key=');
          } else if (token.startsWith('--default=')) {
            if (!allowModelOptions) {
              throw ForgeException(
                '--default is only supported for make:model.',
              );
            }
            defaultValue = _optionValue(token, '--default=');
          } else {
            throw ForgeException('Unknown field option "$token".');
          }
      }
    }

    return FieldDefinition(
      type: type,
      name: name,
      isRequired: isRequired,
      jsonKey: jsonKey,
      defaultValue: defaultValue,
    );
  }

  String _optionValue(String token, String prefix) {
    final value = token.substring(prefix.length);
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }

  List<String> _tokenize(String input) {
    final matches = RegExp(
      r'''(?:[^\s"']+|"[^"]*"|'[^']*')+''',
    ).allMatches(input.trim());
    return matches.map((match) => match.group(0)!).toList();
  }
}
