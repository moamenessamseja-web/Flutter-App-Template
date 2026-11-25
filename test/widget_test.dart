import 'package:app_template/app.dart';
import 'package:app_template/domain/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts in Arabic, right-to-left', (tester) async {
    AppLanguage.code = 'ar';
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('مرحبًا'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('مرحبًا'))), TextDirection.rtl);
  });

  testWidgets('English flips the text and the direction', (tester) async {
    addTearDown(() => AppLanguage.code = 'ar');
    AppLanguage.code = 'en';
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Hello'))), TextDirection.ltr);
  });
}
