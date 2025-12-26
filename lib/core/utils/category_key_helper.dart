class CategoryKeyHelper {
  static String normalize(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s/]'), '') // removes emojis & symbols
        .trim();
  }
}
