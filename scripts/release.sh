#!/usr/bin/env bash
# Builds, signs (Developer ID), notarizes and staples BluetoothBatteryWatch, publishes a GitHub
# release and updates the Homebrew cask in bombadiltom/homebrew-tap.
#
# Usage:  scripts/release.sh <version>            e.g. scripts/release.sh 1.0
#         scripts/release.sh <version> --no-publish   (build + notarize only, no GitHub/tap changes)
#
# One-time prerequisites (see README.md → Releasing):
#   - a "Developer ID Application" certificate in the login keychain
#   - notarization credentials stored with:
#       xcrun notarytool store-credentials BluetoothBatteryWatch --apple-id <apple-id> --team-id <team-id>
#   - gh logged in as $GH_USER (default: bombadiltom)
set -euo pipefail

VERSION="${1:?usage: scripts/release.sh <version> [--no-publish]}"
PUBLISH=1
[[ "${2:-}" == "--no-publish" ]] && PUBLISH=0

APP_NAME="BluetoothBatteryWatch"
REPO="bombadiltom/BluetoothBatteryWatch"
TAP_REPO="bombadiltom/homebrew-tap"
CASK_TOKEN="bluetoothbatterywatch"
BUNDLE_ID="de.lorenz-unna.batterywatch"
NOTARY_PROFILE="${NOTARY_PROFILE:-BluetoothBatteryWatch}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application}"
TEAM_ID="${TEAM_ID:-K6QN2C7Q55}"
GH_USER="${GH_USER:-bombadiltom}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ $PUBLISH -eq 1 ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "error: working tree is not clean — commit first so the release matches a tag." >&2
    exit 1
  fi
  if git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null; then
    echo "error: tag v$VERSION already exists." >&2
    exit 1
  fi
fi

if ! security find-identity -v -p codesigning | grep -q "$SIGN_IDENTITY"; then
  echo "error: no \"$SIGN_IDENTITY\" certificate in the keychain." >&2
  exit 1
fi

BUILD_DIR="$ROOT/build/release"
DIST_DIR="$ROOT/dist"
APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
ZIP="$DIST_DIR/$APP_NAME-$VERSION.zip"

echo "==> Building $APP_NAME $VERSION"
xcodegen generate --quiet
rm -rf "$BUILD_DIR"
mkdir -p "$DIST_DIR"
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  -destination "generic/platform=macOS" \
  MARKETING_VERSION="$VERSION" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CURRENT_PROJECT_VERSION="$(git rev-list --count HEAD)" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  build | grep -E "error|warning: |BUILD" || true
[[ -d "$APP" ]] || { echo "error: build failed" >&2; exit 1; }

codesign --verify --deep --strict --verbose=2 "$APP"

echo "==> Notarizing (this usually takes a few minutes)"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
SUBMISSION="$(xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json)"
SUBMISSION_ID="$(plutil -extract id raw - <<<"$SUBMISSION")"
STATUS="$(plutil -extract status raw - <<<"$SUBMISSION")"
echo "    submission $SUBMISSION_ID: $STATUS"
if [[ "$STATUS" != "Accepted" ]]; then
  echo "error: notarization was not accepted. Apple's log:" >&2
  xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$NOTARY_PROFILE" >&2
  exit 1
fi
xcrun stapler staple "$APP"
spctl --assess --type execute --verbose=2 "$APP"

# Re-zip so the download contains the stapled ticket.
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
SHA256="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
echo "==> $ZIP"
echo "    sha256 $SHA256"

if [[ $PUBLISH -eq 0 ]]; then
  echo "==> --no-publish: skipping tag, GitHub release and cask update."
  exit 0
fi

GH_TOKEN="$(gh auth token --user "$GH_USER")"
export GH_TOKEN

echo "==> Tagging v$VERSION and publishing the GitHub release"
git tag -a "v$VERSION" -m "$APP_NAME $VERSION"
git push origin "v$VERSION"
gh release create "v$VERSION" "$ZIP" --repo "$REPO" --title "$APP_NAME $VERSION" --generate-notes

echo "==> Updating the Homebrew cask in $TAP_REPO"
TAP_DIR="$(mktemp -d)"
trap 'rm -rf "$TAP_DIR"' EXIT
git clone --quiet "git@github.com:$TAP_REPO.git" "$TAP_DIR"
mkdir -p "$TAP_DIR/Casks"
cat > "$TAP_DIR/Casks/$CASK_TOKEN.rb" <<EOF
cask "$CASK_TOKEN" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/$REPO/releases/download/v#{version}/$APP_NAME-#{version}.zip"
  name "$APP_NAME"
  desc "Menu bar battery levels and low-battery alerts for Bluetooth accessories"
  homepage "https://github.com/$REPO"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "$APP_NAME.app"

  uninstall quit: "$BUNDLE_ID"

  zap trash: "~/Library/Preferences/$BUNDLE_ID.plist"
end
EOF
git -C "$TAP_DIR" add "Casks/$CASK_TOKEN.rb"
git -C "$TAP_DIR" commit --quiet -m "$CASK_TOKEN $VERSION"
git -C "$TAP_DIR" push --quiet origin HEAD

echo "==> Released $APP_NAME $VERSION"
echo "    brew install --cask bombadiltom/tap/$CASK_TOKEN"
