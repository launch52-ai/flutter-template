#!/bin/bash
# Upload dSYMs to Sentry
#
# Usage:
#   ./upload_dsyms_sentry.sh
#
# This script is called from:
#   - Xcode Build Phase (local builds)
#   - CI/CD workflow (automated builds)
#
# Prerequisites:
#   - sentry-cli installed (brew install getsentry/tools/sentry-cli)
#   - SENTRY_AUTH_TOKEN environment variable
#   - SENTRY_ORG environment variable
#   - SENTRY_PROJECT environment variable
#
# For CI/CD, set these as GitHub Secrets:
#   - SENTRY_AUTH_TOKEN
#   - SENTRY_ORG
#   - SENTRY_PROJECT

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Uploading dSYMs to Sentry...${NC}"

# Check for sentry-cli
if ! command -v sentry-cli &> /dev/null; then
    echo -e "${RED}Error: sentry-cli not found${NC}"
    echo "Install with: brew install getsentry/tools/sentry-cli"
    exit 1
fi

# Check required environment variables
if [ -z "$SENTRY_AUTH_TOKEN" ]; then
    echo -e "${RED}Error: SENTRY_AUTH_TOKEN not set${NC}"
    exit 1
fi

if [ -z "$SENTRY_ORG" ]; then
    echo -e "${RED}Error: SENTRY_ORG not set${NC}"
    exit 1
fi

if [ -z "$SENTRY_PROJECT" ]; then
    echo -e "${RED}Error: SENTRY_PROJECT not set${NC}"
    exit 1
fi

# Check if running in Xcode context
if [ -n "$DWARF_DSYM_FOLDER_PATH" ]; then
    echo "Running in Xcode context"
    DSYM_PATH="$DWARF_DSYM_FOLDER_PATH"
else
    # CI/CD context - find dSYMs in build output
    echo "Running in CI/CD context"

    # Default path for flutter build ipa output
    DSYM_PATH="build/ios/archive/Runner.xcarchive/dSYMs"

    if [ ! -d "$DSYM_PATH" ]; then
        # Try alternative path
        DSYM_PATH="build/ios/ipa"
    fi
fi

# Verify dSYMs exist
if [ ! -e "$DSYM_PATH" ]; then
    echo -e "${RED}Error: dSYMs not found at $DSYM_PATH${NC}"
    echo "Make sure you've built the app in Release mode first."
    exit 1
fi

# Upload dSYMs with source context
echo "Uploading from: $DSYM_PATH"
sentry-cli debug-files upload \
    --include-sources \
    --org "$SENTRY_ORG" \
    --project "$SENTRY_PROJECT" \
    "$DSYM_PATH"

echo -e "${GREEN}dSYMs uploaded to Sentry successfully!${NC}"
