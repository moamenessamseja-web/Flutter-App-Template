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
- Commit `pubspec.lock`; the pub cache key uses its hash.
- The applicationId is fixed by the pubspec `name` (+ `--org`). Decide it BEFORE the first APK is installed on the owner's phone; it cannot change afterwards without uninstalling.
- Work on `agent/<task>`, open a PR with the agent's own PAT (a PR opened with `GITHUB_TOKEN` does not start CI). Merge to `main` only after the owner device-tested.

## Facts of this repository (generated from Flutter-App-Template)
- `android/` is NOT committed: the central workflow generates it on every build (`flutter create --platforms=android --project-name <pubspec name> --org com.moamen`). To commit it instead, run that command somewhere with Flutter and commit the result.
- The applicationId is `com.moamen.<name in pubspec.yaml>`. Decide the pubspec `name` once, before the first APK is installed on the phone. The template's placeholder name is `app_template`; rename it (also in `test/widget_test.dart`) for the real app.
- `pubspec.lock` cannot be created without Flutter; once the first build exists, pin dependency versions exactly in `pubspec.yaml`.
- `.agent/HTTP_ONLY.md` is a copy of the gateway's file of the same name (the HTTP-only fallback). After `init_agent.py` creates `.agent/README.md`, add `HTTP_ONLY.md` to its file index (otherwise `agent_audit.py` warns).
