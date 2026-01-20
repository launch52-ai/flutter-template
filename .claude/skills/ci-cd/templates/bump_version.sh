#!/bin/bash
# Version bump script for Flutter projects
#
# Usage:
#   ./scripts/bump_version.sh [major|minor|patch|build] [--tag]
#
# Examples:
#   ./scripts/bump_version.sh patch        # 1.0.0 → 1.0.1
#   ./scripts/bump_version.sh minor        # 1.0.1 → 1.1.0
#   ./scripts/bump_version.sh major        # 1.1.0 → 2.0.0
#   ./scripts/bump_version.sh build        # Only increment build number
#   ./scripts/bump_version.sh patch --tag  # Bump + create git tag

set -e

PUBSPEC="pubspec.yaml"

# Check pubspec exists
if [ ! -f "$PUBSPEC" ]; then
  echo "Error: $PUBSPEC not found"
  exit 1
fi

# Get current version
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Parse version components
MAJOR=$(echo "$VERSION_NAME" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_NAME" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_NAME" | cut -d'.' -f3 | cut -d'-' -f1)

echo "Current version: $CURRENT_VERSION"

# Determine bump type
BUMP_TYPE=${1:-patch}

case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  build)
    # Only bump build number
    ;;
  *)
    echo "Usage: $0 [major|minor|patch|build] [--tag]"
    echo ""
    echo "Options:"
    echo "  major   Bump major version (breaking changes)"
    echo "  minor   Bump minor version (new features)"
    echo "  patch   Bump patch version (bug fixes)"
    echo "  build   Only increment build number"
    echo "  --tag   Create git tag after bumping"
    exit 1
    ;;
esac

# Increment build number
NEW_BUILD=$((BUILD_NUMBER + 1))

# Alternative: timestamp-based build number
# NEW_BUILD=$(date +%Y%m%d%H%M)

NEW_VERSION="$MAJOR.$MINOR.$PATCH+$NEW_BUILD"

echo "New version: $NEW_VERSION"

# Update pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
else
  # Linux
  sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
fi

echo "Updated $PUBSPEC"

# Create git tag if requested
if [[ "$*" == *"--tag"* ]]; then
  TAG_NAME="v$MAJOR.$MINOR.$PATCH"

  git add "$PUBSPEC"
  git commit -m "Bump version to $NEW_VERSION"
  git tag -a "$TAG_NAME" -m "Release $MAJOR.$MINOR.$PATCH"

  echo ""
  echo "Created tag: $TAG_NAME"
  echo "To push: git push origin main --tags"
fi

echo ""
echo "Done!"
