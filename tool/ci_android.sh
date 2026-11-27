#!/usr/bin/env bash
# Runs in CI after `flutter create` generated android/ (android/ is NOT committed). Called through the gateway input
# `pre_build_command: "bash tool/ci_android.sh"` (see .github/workflows/build-apk.yml).
#
# Inputs (plain files, edited by the agent / owner):
#   tool/android_label.txt     first non-comment line = the launcher name shown under the icon (any language)
#   tool/android_features.txt  one feature per line (# comments allowed). Available: notifications
#
# Every injection verifies its own result and the script is idempotent, so a wrong assumption about the generated
# files fails the build loudly instead of shipping a silently broken app. Dry-run it locally on a mock manifest first.
set -euo pipefail

manifest="android/app/src/main/AndroidManifest.xml"
test -f "$manifest" || { echo "missing $manifest"; exit 1; }

first_line() { # prints the first non-comment, non-empty line of a file ("" if none or file missing)
  [ -f "$1" ] || return 0
  grep -v '^[[:space:]]*#' "$1" | grep -v '^[[:space:]]*$' | head -n 1 | sed 's/[[:space:]]*$//' || true
}

# ---- launcher label ----------------------------------------------------------------------------------------------
label="$(first_line tool/android_label.txt)"
if [ -n "$label" ]; then
  # The value goes into an XML attribute (so & < > " must be escaped) and through sed (so \ | & must be escaped again).
  xml="$(printf '%s' "$label" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g')"
  sed_safe="$(printf '%s' "$xml" | sed -e 's/[\\|&]/\\&/g')"
  sed -i "s|android:label=\"[^\"]*\"|android:label=\"${sed_safe}\"|" "$manifest"
  grep -qF "android:label=\"${xml}\"" "$manifest" || { echo "could not set the app label"; exit 1; }
  echo "launcher label set: $label"
fi

# ---- features ----------------------------------------------------------------------------------------------------
gradle="android/app/build.gradle.kts"
[ -f "$gradle" ] || gradle="android/app/build.gradle"

inject_notifications() {
  # What flutter_local_notifications needs natively (proven on the owner's phone: manager-assistant-ready d2a17ef,
  # addadi 5520f0b): permissions, boot + scheduled receivers, core-library desugaring, R8 keep rules.
  # No SCHEDULE_EXACT_ALARM: use inexact alarms (AndroidScheduleMode.inexactAllowWhileIdle) unless exactness is required.
  local perms receivers
  perms='    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
  grep -q 'POST_NOTIFICATIONS' "$manifest" || sed -i "0,/<application/s|<application|${perms}\n    <application|" "$manifest"
  if ! grep -q 'ScheduledNotificationReceiver' "$manifest"; then
    receivers='        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />\n        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n            <intent-filter>\n                <action android:name="android.intent.action.BOOT_COMPLETED"/>\n                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>\n                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>\n                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>\n            </intent-filter>\n        </receiver>'
    sed -i "0,/android:icon=\"@mipmap\/ic_launcher\">/s||android:icon=\"@mipmap/ic_launcher\">\n${receivers}|" "$manifest"
  fi
  for needle in POST_NOTIFICATIONS RECEIVE_BOOT_COMPLETED ScheduledNotificationReceiver ScheduledNotificationBootReceiver; do
    grep -q "$needle" "$manifest" || { echo "manifest injection failed: $needle"; exit 1; }
  done
  test -f "$gradle" || { echo "missing android/app/build.gradle(.kts)"; exit 1; }
  cat > android/app/proguard-rules.pro <<'PRO'
# flutter_local_notifications keeps scheduled-notification data through Gson reflection
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
PRO
  if ! grep -q 'desugar_jdk_libs' "$gradle"; then
    if [[ "$gradle" == *.kts ]]; then
      cat >> "$gradle" <<'KTS'

android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
KTS
    else
      cat >> "$gradle" <<'GROOVY'

android {
    compileOptions {
        coreLibraryDesugaringEnabled true
    }
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
GROOVY
    fi
  fi
  grep -q 'desugar_jdk_libs' "$gradle" || { echo "desugaring injection failed"; exit 1; }
  echo "feature injected: notifications"
}

if [ -f tool/android_features.txt ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    feature="$(printf '%s' "$line" | sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$feature" ] && continue
    case "$feature" in
      notifications) inject_notifications ;;
      *) echo "unknown feature in tool/android_features.txt: $feature"; exit 1 ;;
    esac
  done < tool/android_features.txt
fi
echo "android customisation done"
