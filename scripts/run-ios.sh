#!/usr/bin/env bash
set -euxo pipefail

# --- EDIT THESE IF NEEDED ---
PROJECT="Budget.xcodeproj"                                   # <- must be the .xcodeproj bundle name
SCHEME="${SCHEME:-Budget}"                                    # <- fallback scheme name
UDID="${UDID:-3DFD0E42-7D06-4910-A3B7-95A670972522}"         # <- your simulator UDID
MIN_IOS="${MIN_IOS:-18.2}"                                    # avoid 18.5 vs 18.2 warning
DERIVED="${DERIVED:-build}"
# ----------------------------

cd /Users/user286010/BudgetApp

# Sanity: project must be a directory, not project.pbxproj
test -d "$PROJECT" || { echo "❌ Not found: $PROJECT (expected a folder like Budget.xcodeproj)"; exit 1; }

# If SCHEME is wrong, auto-detect first available scheme from the project
if ! xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings >/dev/null 2>&1; then
  SCHEME="$(xcodebuild -project "$PROJECT" -list -json 2>/dev/null \
    | tr -d '\r' \
    | sed -n 's/.*"schemes":[^[]*\[\([^]]*\)\].*/\1/p' \
    | sed 's/[",]//g' | tr -s ' ' '\n' | head -n1 || true)"
fi
[ -n "$SCHEME" ] || { echo "❌ Could not detect a scheme in $PROJECT"; exit 1; }
echo "ℹ️ Using scheme: $SCHEME"

# Boot simulator
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b || true
open -a Simulator || true

# Build a generic simulator slice
xcodebuild -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" \
  IPHONEOS_DEPLOYMENT_TARGET="$MIN_IOS" \
  -showBuildTimingSummary

# Find .app
APP="$(find "$DERIVED/Build/Products/Debug-iphonesimulator" -maxdepth 1 -type d -name '*.app' | head -n1)"
[ -n "$APP" ] && [ -d "$APP" ] || { echo "❌ .app not found in $DERIVED/Build/Products/Debug-iphonesimulator"; exit 1; }
echo "ℹ️ App: $APP"

# Get bundle id, install, launch
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist" 2>/dev/null || true)"
[ -n "$BUNDLE_ID" ] || { echo "❌ CFBundleIdentifier not found"; exit 1; }

xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" "$BUNDLE_ID"
echo "✅ Launched $BUNDLE_ID on $UDID (scheme: $SCHEME)"
