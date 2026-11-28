# Recipes (proven on the owner's phone or in CI)

The reference implementation of everything below is the app **addadi** (`moamenessamseja-web/addadi`, tag `phase2-paused-2026-11-16`,
last code commit `5520f0b`). Read its `lib/` before inventing your own.

## 1. Plugin versions that are proven
| Package | Version | Evidence |
|---|---|---|
| `flutter_local_notifications` | `17.2.4` (exact) | built in CI and delivered notifications on the owner's phone (manager-assistant-ready d2a17ef); newer majors change the API |
| `timezone` | `0.9.4` (exact) | same |
| `shared_preferences` | `^2.3.0` | ran on the owner's phone with addadi. Known trap: `shared_preferences_android` 2.5.0 gave a black screen on this phone in manager-assistant-ready; fix there: `dependency_overrides: shared_preferences_android: 2.4.28`. 2026-11-27: an app built from this template with `shared_preferences` 2.5.6 / `shared_preferences_android` 2.5.5 (resolved by CI) started and rendered on the same phone; its API was not called, so only startup is covered |
| `share_plus` | `^11.0.0` | compiled in CI (addadi); API `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`; never run on the phone |

Commit `pubspec.lock` if it exists (the pub cache key uses its hash). If it does not exist yet: pin exact versions from the `Resolved dependencies` annotation of a green build; CI lockfile generation is roadmap item D1. Read it with `gh_ci.sh result <branch>`.

## 2. Storage
Keep `KeyValueStorage` (lib/data/storage.dart). The device implementation:
```dart
class PrefsStorage implements KeyValueStorage {
  PrefsStorage(this._prefs);
  final SharedPreferences _prefs;
  static Future<PrefsStorage> open() async => PrefsStorage(await SharedPreferences.getInstance());
  @override Future<String?> read(String key) async => _prefs.getString(key);
  @override Future<void> write(String key, String value) async {
    if (!await _prefs.setString(key, value)) throw StateError('could not write $key');
  }
}
```
Write to storage first, notify listeners after: "saved" is then always true. Keep one JSON document with a version field.

## 3. Local notifications
Add `notifications` to `tool/android_features.txt` (permissions, boot/scheduled receivers, desugaring, R8 keep rules are injected in CI).
Design that worked (addadi `lib/domain/notifications.dart`, `lib/data/plugin_notifications.dart`): backend interface + fake backend in tests;
schedule at an absolute moment; re-arm on every save / setting change / app start; never schedule the past; inexact alarms
(`AndroidScheduleMode.inexactAllowWhileIdle`) need no special permission; one alert per meter per latest reading, persisted;
preference and OS permission are separate; a notification failure must never fail a saved action.

## 4. Language switch
Strings table (this template). To switch live: the store sets `AppLanguage.code`, THEN notifies; `MaterialApp.locale` follows it.
Numbers and dates stay Latin and are wrapped in left-to-right runs inside Arabic text. When adding the second language late, the
removal of `const` from every widget that uses `S.x` can be automated (addadi LESSONS L8).

## 5. Flutter APIs avoided on purpose (CI feedback is slow, Flutter changes fast)
No component themes in `ThemeData` (`CardTheme`/`AppBarTheme`/`InputDecorationTheme` changed types across versions); `ColorScheme(...)`
with only the required fields; `Color.withValues` instead of `withOpacity`; no `DropdownButtonFormField(value:)`; no `MaterialStateProperty`;
no `Radio`; chips/segmented buttons/switch tiles without colour overrides.

## 6. Testing without a Flutter SDK
Logic that imports no Flutter runs locally in seconds: `python3 <gateway>/.skills/engineer-in-charge/scripts/pure_dart_tests.py .`
(downloads a plain Dart SDK once). Widgets and plugins are verified only by CI.
