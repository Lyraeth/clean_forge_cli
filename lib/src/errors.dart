class ForgeException implements Exception {
  ForgeException(this.message);

  final String message;

  @override
  String toString() => message;
}
