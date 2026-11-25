/// Persistence behind a small interface, so the logic that uses it can be tested without a device.
/// The real on-device implementation (shared_preferences) is a recipe in docs/RECIPES.md, added only when the app needs it.
abstract class KeyValueStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemoryStorage implements KeyValueStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
