class CliUi {
  const CliUi._();

  static void box(String title, List<String> lines) {
    final content = [title, ...lines];
    final width = content.fold<int>(
      0,
      (max, line) => line.length > max ? line.length : max,
    );
    final border = '+-${'-' * width}-+';

    print(border);
    print('| ${title.padRight(width)} |');
    print(border);
    for (final line in lines) {
      print('| ${line.padRight(width)} |');
    }
    print(border);
  }

  static void success(String message) {
    print('');
    box('Done', [message]);
  }
}
