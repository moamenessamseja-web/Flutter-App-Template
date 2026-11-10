import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Hello'), findsOneWidget);
  });
}
