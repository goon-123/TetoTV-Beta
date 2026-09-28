#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo 'This build requires macOS with Xcode and CocoaPods.' >&2
  exit 1
fi
readonly IOS_REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${IOS_REPO_ROOT}"
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export COCOAPODS_DISABLE_STATS=true
readonly IOS_BUILD_NAME="${TETOTV_IOS_BUILD_NAME:-0.1.0}"
readonly IOS_BUILD_NUMBER="${TETOTV_IOS_BUILD_NUMBER:-1}"

flutter pub get --enforce-lockfile
flutter build ios --release --no-codesign \
  --build-name="${IOS_BUILD_NAME}" --build-number="${IOS_BUILD_NUMBER}" \
  --dart-define-from-file=config/ios.json
readonly IOS_APP="${IOS_REPO_ROOT}/build/ios/iphoneos/Runner.app"
python3 tool/ios/verify_bundle.py "${IOS_APP}"

readonly IOS_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/tetotv-ipa.XXXXXX")"
trap 'rm -rf -- "${IOS_STAGE}"' EXIT
mkdir -p "${IOS_STAGE}/Payload" build/ios/ipa
ditto "${IOS_APP}" "${IOS_STAGE}/Payload/Runner.app"
ditto -c -k --keepParent "${IOS_STAGE}/Payload" \
  "${IOS_REPO_ROOT}/build/ios/ipa/TetoTV-iOS-unsigned.ipa"
echo 'Created build/ios/ipa/TetoTV-iOS-unsigned.ipa'
