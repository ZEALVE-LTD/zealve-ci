#!/usr/bin/env bash
# Prepare a Linux self-hosted Actions runner host for the zealve-ci reusable
# workflows. Idempotent — safe to re-run.
#
#   sudo bin/prep-build-runner.sh --android      # Android SDK (vps3 layout)
#
# What --android does:
#   - installs OpenJDK 17 (temurin via apt if missing)
#   - installs the Android SDK cmdline-tools at /opt/android-sdk
#   - accepts the SDK licenses, installs platform-tools, android-35/36
#     platforms, build-tools;35.0.0 and NDK 27.1.12297006
#   - writes ANDROID_HOME / ANDROID_SDK_ROOT into every runner's .env under
#     /opt/actions-runner*/ so Gradle finds the SDK (the reusable workflow
#     also sets ANDROID_HOME itself, so this is belt-and-braces)
set -euo pipefail

SDK_ROOT=${ANDROID_SDK_ROOT:-/opt/android-sdk}
CMDLINE_TOOLS_ZIP=https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
PLATFORMS="android-35 android-36"
BUILD_TOOLS="35.0.0"
NDK="27.1.12297006"

[[ ${1:-} == "--android" ]] || { echo "usage: $0 --android" >&2; exit 1; }
[[ $EUID -eq 0 ]] || { echo "run as root (sudo)" >&2; exit 1; }

# 1. JDK 17
if ! command -v java >/dev/null || ! java -version 2>&1 | grep -q '"17'; then
  apt-get update -qq && apt-get install -y -qq openjdk-17-jdk-headless
fi

# 2. cmdline-tools
if [[ ! -x $SDK_ROOT/cmdline-tools/latest/bin/sdkmanager ]]; then
  mkdir -p "$SDK_ROOT/cmdline-tools"
  curl -fsSL "$CMDLINE_TOOLS_ZIP" -o /tmp/cmdline-tools.zip
  unzip -q /tmp/cmdline-tools.zip -d /tmp/clt
  mv /tmp/clt/cmdline-tools "$SDK_ROOT/cmdline-tools/latest"
  rm -rf /tmp/cmdline-tools.zip /tmp/clt
fi
SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"

# 3. Licenses + packages
yes | "$SDKMANAGER" --licenses >/dev/null
"$SDKMANAGER" "platform-tools" ${PLATFORMS/ //"platforms;"/} \
  "build-tools;$BUILD_TOOLS" "ndk;$NDK" >/dev/null

# 4. Runner .env files
for env in /opt/actions-runner*/.env; do
  [[ -e $env ]] || continue
  grep -q '^ANDROID_HOME=' "$env" 2>/dev/null || echo "ANDROID_HOME=$SDK_ROOT" >> "$env"
  grep -q '^ANDROID_SDK_ROOT=' "$env" 2>/dev/null || echo "ANDROID_SDK_ROOT=$SDK_ROOT" >> "$env"
done

echo "OK: Android SDK ready at $SDK_ROOT"
