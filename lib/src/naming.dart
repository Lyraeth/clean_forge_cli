String toSnakeCase(String input) {
  final normalized = input
      .trim()
      .replaceAll(RegExp(r'[\s\-]+'), '_')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      );

  return normalized.toLowerCase();
}

String toPascalCase(String input) {
  final separated = input.trim().replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );
  final words = separated
      .split(RegExp(r'[\s_\-]+'))
      .where((word) => word.isNotEmpty);

  return words
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join();
}

String stripSuffix(String value, String suffix) {
  if (!value.endsWith(suffix) || value.length == suffix.length) {
    return value;
  }

  return value.substring(0, value.length - suffix.length);
}
