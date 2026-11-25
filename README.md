# Flutter App Template

Template repository for new Flutter/Android apps. Everything else (CI workflow, agent rules, skills, scripts) lives in
[Flutter-Android-Build](https://github.com/moamenessamseja-web/Flutter-Android-Build).

**Create a new app:** "Use this template", or `POST /repos/moamenessamseja-web/Flutter-App-Template/generate` (see `.agent/RUN.md` in the gateway).
Then: `bash tool/rename_app.sh <package_name> "<Launcher label>"`, give an agent the idea, and read `AGENTS.md`.

What you get: a minimal app (Arabic/English strings table, right-to-left, layers `lib/domain`, `lib/data`, `lib/ui`, tests), the caller
workflow (builds an APK on every pull request through the gateway and checks the `.agent/` memory), `tool/ci_android.sh` for native
Android customisation, and `docs/RECIPES.md` with proven plugin versions and patterns.
