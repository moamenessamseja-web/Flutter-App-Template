/// All user-visible text, Arabic and English side by side: one table, one getter per key.
/// Getters are NOT const, so a widget that uses them cannot be const either (write `Text(S.hello)`, not `const Text(...)`).
/// Add a key in `table` and a getter; test/strings_test.dart fails if a language is missing or in the wrong script.
import '../domain/language.dart';

class S {
  const S._();

  static String _t(String key) => table[key]![AppLanguage.isArabic ? 0 : 1];

  static String get appName => _t('appName');
  static String get hello => _t('hello');

  /// key -> [Arabic, English]
  static const Map<String, List<String>> table = {
    'appName': ['تطبيق', 'App'],
    'hello': ['مرحبًا', 'Hello'],
  };
}
