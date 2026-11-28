# Agent instructions

Before any work in this repository, use the central engineering gateway:
1. `git clone --depth 1 https://github.com/moamenessamseja-web/Flutter-Android-Build.git /tmp/gateway`
2. Read `/tmp/gateway/.agent/README.md` and follow it (it points to the Engineering in Charge skill, which you must read first), then `/tmp/gateway/.agent/RUN.md` for the delivery recipe.
3. This repository's own memory is in `.agent/` (create it with the gateway's `init_agent.py` if missing). Read it after the gateway.
4. Never assume this project has the same architecture as another one; inspect it first.

## If your harness has no bash/git
If your harness has no bash/git, follow `.agent/HTTP_ONLY.md` instead.
No git? Fetch the gateway files directly (no token, public repo):
`https://raw.githubusercontent.com/moamenessamseja-web/Flutter-Android-Build/main/<path>`
Start with `.agent/README.md`, then `.agent/ACCESS.md`, then `.agent/HTTP_ONLY.md`.
You cannot run the gate scripts in that mode; HTTP_ONLY.md defines the API equivalents.

## Facts to respect in every target repository
- `.github/workflows/build-apk.yml` calls the gateway's reusable workflow. Keep the Flutter version pinned.
- Commit `pubspec.lock` if it exists (the pub cache key uses its hash). If it does not exist yet: pin exact versions from the `Resolved dependencies` annotation of a green build; CI lockfile generation is roadmap item D1.
- The applicationId is fixed by the pubspec `name` (+ `--org`). Decide it BEFORE the first APK is installed on the owner's phone; it cannot change afterwards without uninstalling.
- Work on `agent/<task>`, open a PR with the agent's own PAT (a PR opened with `GITHUB_TOKEN` does not start CI). Merge to `main` only after the owner device-tested.

## Facts of this repository (generated from Flutter-App-Template)
- **First step for a new app: run the rename, once, before any APK is installed:** `bash tool/rename_app.sh <package_name> "<Launcher label>" [--org com.example]`. It sets the pubspec name, the package imports, the launcher label and (optionally) the organisation. The Android applicationId is `<org>.<package_name>` (default org `com.moamen`) and cannot change after the first install on a phone. Ask the owner for the name and label; do not guess.
- `android/` is NOT committed: the central workflow generates it on every build (`flutter create --platforms=android --project-name <pubspec name> --org <org>`), then `tool/ci_android.sh` applies `tool/android_label.txt` and the features listed in `tool/android_features.txt` (available: `notifications`). Native changes go through that script (dry-run it on a mock manifest first) or by committing `android/` once.
- Layers: `lib/domain` (pure Dart, no Flutter imports, unit-tested without a device), `lib/data` (storage behind an interface), `lib/ui` (strings table Arabic/English, widgets). Strings are getters over one table: write `Text(S.hello)`, never `const Text(S.hello)`.
- Tests: `python3 <gateway>/.skills/engineer-in-charge/scripts/pure_dart_tests.py .` runs the pure ones in seconds; widget/plugin tests run only in CI.
- Flutter is pinned in `.github/workflows/build-apk.yml` (3.47.9). Commit `pubspec.lock` if it exists (the pub cache key uses its hash). If it does not exist yet: pin exact versions from the `Resolved dependencies` annotation of a green build; CI lockfile generation is roadmap item D1. (`gh_ci.sh result <branch>`).
- Proven plugin versions, storage/notification/export/language recipes and the Flutter APIs to avoid: `docs/RECIPES.md`. The reference app is `moamenessamseja-web/addadi` (tag `phase2-paused-2026-11-16`).
- `.agent/HTTP_ONLY.md` is a copy of the gateway file of the same name. After `init_agent.py` creates `.agent/README.md`, add `HTTP_ONLY.md` to its file index (otherwise `agent_audit.py` warns).
