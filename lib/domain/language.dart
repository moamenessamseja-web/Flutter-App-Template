/// Pure Dart: the app language, read by the UI strings (and by domain labels when you add them).
/// One global is enough for a one-user app; whoever changes the language sets it BEFORE notifying the UI.
library;

class AppLanguage {
  const AppLanguage._();

  /// 'ar' or 'en'.
  static String code = 'ar';

  static bool get isArabic => code != 'en';
}
