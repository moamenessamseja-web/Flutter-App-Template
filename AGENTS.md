# Agent instructions

Before any work in this repository, use the central engineering gateway:
1. `git clone --depth 1 https://github.com/moamenessamseja-web/Flutter-Android-Build.git /tmp/gateway`
2. Read `/tmp/gateway/.agent/README.md` and follow it (it points to the Engineering in Charge skill, which you must read first), then `/tmp/gateway/.agent/RUN.md` for the delivery recipe.
3. This repository's own memory is in `.agent/`. If it is missing, create it: `python3 /tmp/gateway/.skills/engineer-in-charge/scripts/init_agent.py --project "<name>" --stack "Flutter/Android" --repo .`
4. Inspect this project before changing anything; never assume it has the same architecture as another one.

Facts of this repository
- `android/` is NOT committed: the central workflow generates it on every build (`flutter create --platforms=android`). To commit it instead, run `flutter create --platforms=android --org com.moamen .` somewhere with Flutter and commit the result.
- The applicationId is `com.moamen.<name in pubspec.yaml>` (set by `scaffold_args` in `.github/workflows/build-apk.yml`). Decide the pubspec `name` once, before the first APK is installed on the phone.
- Flutter is pinned in `.github/workflows/build-apk.yml`. Pin dependency versions exactly in `pubspec.yaml`.
