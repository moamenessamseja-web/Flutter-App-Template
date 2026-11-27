#!/usr/bin/env bash
# Gives a repository generated from this template its real identity. Run it ONCE, before the first APK is installed.
#
#   bash tool/rename_app.sh <package_name> "<Launcher label>" [--org com.example]
#
# package_name: lowercase snake_case (e.g. my_app). The Android applicationId becomes <org>.<package_name> and it
#               CANNOT change after an APK was installed on a phone without uninstalling the app.
# label:        the name under the launcher icon (any language).
# --org:        reverse-domain prefix of the applicationId (default: unchanged in .github/workflows/build-apk.yml).
set -euo pipefail

new="${1:?usage: rename_app.sh <package_name> \"<Launcher label>\" [--org com.example]}"
label="${2:?usage: rename_app.sh <package_name> \"<Launcher label>\" [--org com.example]}"
shift 2
org=""
while [ $# -gt 0 ]; do
  case "$1" in
    --org) org="${2:?--org needs a value}"; shift 2 ;;
    *) echo "unknown argument: $1"; exit 2 ;;
  esac
done

[[ "$new" =~ ^[a-z][a-z0-9_]*$ ]] || { echo "package_name must be lowercase snake_case (letters, digits, underscore), got '$new'"; exit 1; }
[ -f pubspec.yaml ] || { echo "run it from the repository root (pubspec.yaml not found)"; exit 1; }
old="$(sed -n 's/^name:[[:space:]]*//p' pubspec.yaml | sed 's/[[:space:]]*#.*$//' | head -n 1 | tr -d "\"' \r")"
[ -n "$old" ] || { echo "no name in pubspec.yaml"; exit 1; }

if [ "$old" != "$new" ]; then
  sed -i "s/^name:[[:space:]]*.*/name: ${new}/" pubspec.yaml
  # package imports
  grep -rl "package:${old}/" lib test 2>/dev/null | while IFS= read -r f; do sed -i "s#package:${old}/#package:${new}/#g" "$f"; done || true
  # mentions in the docs the agent reads
  for f in AGENTS.md README.md docs/RECIPES.md; do
    [ -f "$f" ] && sed -i "s/\b${old}\b/${new}/g" "$f"
  done
fi

# launcher label (single line; the file keeps its comment)
if [ -f tool/android_label.txt ]; then
  { echo "# The launcher name of the app (first non-comment line). Any language."; printf '%s\n' "$label"; } > tool/android_label.txt
fi

if [ -n "$org" ]; then
  [[ "$org" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]] || { echo "--org must look like com.example"; exit 1; }
  sed -i "s#--org [A-Za-z0-9_.]*#--org ${org}#" .github/workflows/build-apk.yml
fi
org_now="$(sed -n 's/.*--org \([A-Za-z0-9_.]*\).*/\1/p' .github/workflows/build-apk.yml | head -n 1)"

echo "renamed: ${old} -> ${new}; launcher label: ${label}"
echo "applicationId will be: ${org_now:-<org>}.${new}   (fixed after the first install on a phone)"
echo "next: run the pure-Dart tests, commit on a branch, open a PR, wait for CI."
