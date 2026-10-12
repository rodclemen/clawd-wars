#!/bin/zsh
# Publishes a release: universal build → (optional) notarization → zip → GitHub release → Homebrew cask.
# Only the newest two GitHub releases are kept; older ones are deleted (their tags stay).
#   ./release.sh 2.14.0            refuses if tag v2.14.0 or its GitHub release already exists
#   ./release.sh 2.14.0 --force    replaces an existing tag and GitHub release
# HEAD must be pushed: it has to equal origin/main.
# Notarization runs when a notarytool keychain profile named "clawd-wars" exists:
#   xcrun notarytool store-credentials clawd-wars --apple-id <you@example.com> --team-id <TEAMID>
# Without it the cask clears the quarantine flag on install instead (like many open-source casks).
set -euo pipefail
cd "${0:A:h}"

VERSION="${1:?usage: ./release.sh <version> [--force]}"
FORCE=0
case "${2:-}" in
    "") ;;
    --force) FORCE=1 ;;
    *) echo "unknown option: $2 (usage: ./release.sh <version> [--force])" >&2; exit 2 ;;
esac
TAG="v$VERSION"
ZIP="build/Clawd-Wars-$VERSION.zip"
TAP_REPO="rodclemen/homebrew-tap"
KEEP_RELEASES=2   # this one and the one before it

[[ -z "$(git status --porcelain)" ]] || { echo "commit your changes first" >&2; exit 1; }
grep -q "^## $VERSION " CHANGELOG.md || { echo "add a '## $VERSION' entry to CHANGELOG.md first" >&2; exit 1; }
git fetch -q origin
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] \
    || { echo "HEAD isn't origin/main: push (or pull) first" >&2; exit 1; }
if [[ $FORCE == 0 ]]; then
    if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null; then
        echo "tag $TAG already exists (pass --force to replace it)" >&2; exit 1
    fi
    if gh release view "$TAG" >/dev/null 2>&1; then
        echo "GitHub release $TAG already exists (pass --force to replace it)" >&2; exit 1
    fi
fi

./build.sh --release "$VERSION"
APP="build/Clawd Wars.app"

if xcrun notarytool history --keychain-profile clawd-wars >/dev/null 2>&1; then
    echo "→ notarizing"
    ditto -c -k --keepParent "$APP" build/notarize.zip
    xcrun notarytool submit build/notarize.zip --keychain-profile clawd-wars --wait
    xcrun stapler staple "$APP"
    NOTARIZED=1
else
    echo "→ no notarytool profile 'clawd-wars': skipping notarization"
    NOTARIZED=0
fi

echo "→ packaging $ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)

echo "→ GitHub release $TAG"
NOTES=$(awk "/^## $VERSION /{f=1;next} /^## /{f=0} f" CHANGELOG.md)
if [[ $FORCE == 1 ]]; then
    git tag -f "$TAG" && git push -f origin "$TAG"
    gh release delete "$TAG" --yes >/dev/null 2>&1 || true
else
    git tag "$TAG" && git push origin "$TAG"
fi
gh release create "$TAG" "$ZIP" --title "Clawd Wars $VERSION" --notes "$NOTES

**Install:** \`brew install --cask rodclemen/tap/clawd-wars\`, or download the zip, unzip, and move *Clawd Wars.app* to Applications."

# Keep the newest $KEEP_RELEASES releases: older zips are never used (the cask names only the latest), and the one
# before the latest stays as a quick rollback. Tags are kept, so every version's code is still marked in git.
for old in $(gh release list --limit 200 --exclude-drafts --json tagName,createdAt \
                 --jq "sort_by(.createdAt) | reverse | .[$KEEP_RELEASES:] | .[].tagName"); do
    gh release delete "$old" --yes && echo "→ removed old release $old (tag kept)"
done

echo "→ Homebrew cask ($TAP_REPO)"
gh repo view "$TAP_REPO" >/dev/null 2>&1 || gh repo create "$TAP_REPO" --public \
    --description "Homebrew tap for Clawd Wars and friends" >/dev/null
TAP=$(mktemp -d)
gh repo clone "$TAP_REPO" "$TAP" -- -q 2>/dev/null || git -C "$TAP" init -q -b main
mkdir -p "$TAP/Casks"
QUARANTINE=""
if [[ $NOTARIZED == 0 ]]; then
    QUARANTINE='
  # Not notarized yet: clear the download quarantine so macOS lets it open.
  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "{{appdir}}/Clawd Wars.app"],
        writable_paths: ["Clawd Wars.app"],
        writable_base:  :appdir
  end
'
fi
cat > "$TAP/Casks/clawd-wars.rb" <<CASK
cask "clawd-wars" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/rodclemen/clawd-wars/releases/download/v#{version}/Clawd-Wars-#{version}.zip"
  name "Clawd Wars"
  desc "Claude Code sessions as a pixel-art Star Wars battle on your desktop"
  homepage "https://github.com/rodclemen/clawd-wars"

  depends_on macos: :ventura

  app "Clawd Wars.app"
$QUARANTINE
  # brew runs this on upgrade too (uninstall, then install): the hooks come out, and the new app puts
  # them back on its next launch.
  uninstall quit:   "com.rodclemen.vaderclaude",
            script: {
              executable: "#{appdir}/Clawd Wars.app/Contents/MacOS/ClawdWars",
              args:       ["--uninstall-hooks"],
            }

  zap trash: [
    "~/.claude/vader-status",
    "~/Library/Application Support/Clawd Wars",
    "~/Library/Screen Savers/Clawd Wars.saver",
    "~/Library/Preferences/com.rodclemen.vaderclaude.plist",
  ]
end
CASK
[[ -f "$TAP/README.md" ]] || printf '# Homebrew tap\n\n```sh\nbrew install --cask rodclemen/tap/clawd-wars\n```\n' > "$TAP/README.md"
git -C "$TAP" add -A
git -C "$TAP" commit -q -m "clawd-wars $VERSION"
git -C "$TAP" remote get-url origin >/dev/null 2>&1 || git -C "$TAP" remote add origin "https://github.com/$TAP_REPO.git"
git -C "$TAP" push -q -u origin main
rm -rf "$TAP"

echo "✓ released $TAG: brew install --cask rodclemen/tap/clawd-wars"
