#!/usr/bin/env bash
# release.sh — Semantic Versioning release helper for zer0sh/dotfiles
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

# 1. Check clean git working tree
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: Working tree has uncommitted changes. Please commit or stash before releasing."
    git status -s
    exit 1
fi

# 2. Get current latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
CURRENT_VERSION="${LATEST_TAG#v}"
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

echo "Current version: $LATEST_TAG"

# 3. Determine next version
BUMP_ARG="${1:-}"

if [[ -z "$BUMP_ARG" ]]; then
    echo ""
    echo "Select bump type:"
    echo "  1) Patch (v$MAJOR.$MINOR.$((PATCH + 1))) — Bug fixes, small tweaks"
    echo "  2) Minor (v$MAJOR.$((MINOR + 1)).0) — New features, components"
    echo "  3) Major (v$((MAJOR + 1)).0.0) — Breaking changes, full reworks"
    echo "  4) Custom version"
    read -rp "Enter choice [1-4] (default: 1): " CHOICE
    case "${CHOICE:-1}" in
        1) BUMP="patch" ;;
        2) BUMP="minor" ;;
        3) BUMP="major" ;;
        4)
           read -rp "Enter version (e.g. v1.0.0): " CUSTOM_INPUT
           BUMP="$CUSTOM_INPUT"
           ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
else
    BUMP="$BUMP_ARG"
fi

case "$BUMP" in
    patch)
        NEW_TAG="v$MAJOR.$MINOR.$((PATCH + 1))"
        ;;
    minor)
        NEW_TAG="v$MAJOR.$((MINOR + 1)).0"
        ;;
    major)
        NEW_TAG="v$((MAJOR + 1)).0.0"
        ;;
    v*.*.*)
        NEW_TAG="$BUMP"
        ;;
    *.*.*)
        NEW_TAG="v$BUMP"
        ;;
    *)
        echo "Error: Invalid version format: $BUMP (expected: patch, minor, major, or vX.Y.Z)"
        exit 1
        ;;
esac

echo ""
echo "Target release: $NEW_TAG"
read -rp "Proceed with tagging and pushing to GitHub? [y/N]: " CONFIRM
if [[ "${CONFIRM,,}" != "y" && "${CONFIRM,,}" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

# 4. Create annotated tag
git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
echo "Created tag $NEW_TAG"

# 5. Push to GitHub
echo "Pushing to GitHub..."
git push origin main
git push origin "$NEW_TAG"

echo ""
echo "Release $NEW_TAG triggered successfully."
echo "GitHub Actions will package assets, create the release, and deploy the wiki:"
echo "https://github.com/zer0sh/dotfiles/releases/tag/$NEW_TAG"
echo "Wiki: https://zer0sh.github.io/dotfiles/"
