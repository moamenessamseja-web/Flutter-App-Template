import 'package:app_template/data/storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MemoryStorage returns what was written and null for unknown keys', () async {
    final s = MemoryStorage();
    expect(await s.read('a'), isNull);
    await s.write('a', '1');
    expect(await s.read('a'), equals('1'));
  });
}
