import 'package:app_template/domain/language.dart';
import 'package:app_template/ui/strings.dart';
import 'package:flutter_test/flutter_test.dart';

final _arabicLetter = RegExp(r'[\u0600-\u06FF]');

void main() {
  test('every key has a non-empty Arabic and English text in the right script', () {
    for (final e in S.table.entries) {
      expect(e.value.length, equals(2));
      expect(_arabicLetter.hasMatch(e.value[0]), isTrue);
      expect(e.value[1].trim().isNotEmpty, isTrue);
      expect(_arabicLetter.hasMatch(e.value[1]), isFalse);
    }
  });

  test('the getters follow the active language', () {
    AppLanguage.code = 'en';
    expect(S.hello, equals('Hello'));
    AppLanguage.code = 'ar';
    expect(S.hello, equals('مرحبًا'));
  });
}
