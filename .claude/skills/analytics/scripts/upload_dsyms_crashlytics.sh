#!/bin/bash
# Upload dSYMs to Firebase Crashlytics
#
# Usage:
#   ./upload_dsyms_crashlytics.sh
#
# This script is called from:
#   - Xcode Build Phase (local builds)
#   - CI/CD workflow (automated builds)
#
# Prerequisites:
#   - GoogleService-Info.plist in ios/Runner/
#   - Firebase Crashlytics SDK installed
#
# Environment variables (for CI):
#   - DWARF_DSYM_FOLDER_PATH: Path to dSYMs (set by Xcode)
#   - DWARF_DSYM_FILE_NAME: dSYM file name (set by Xcode)
#   - INFOPLIST_PATH: Path to Info.plist (set by Xcode)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Uploading dSYMs to Firebase Crashlytics...${NC}"

# Check if running in Xcode context
if [ -n "$DWARF_DSYM_FOLDER_PATH" ] && [ -n "$DWARF_DSYM_FILE_NAME" ]; then
    echo "Running in Xcode context"
    DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
else
    # CI/CD context - find dSYMs in build output
    echo "Running in CI/CD context"

    # Default path for flutter build ipa output
    DSYM_PATH="build/ios/archive/Runner.xcarchive/dSYMs"

    if [ ! -d "$DSYM_PATH" ]; then
        # Try alternative path
        DSYM_PATH="build/ios/ipa/Runner.app.dSYM"
    fi
fi

# Verify dSYMs exist
if [ ! -e "$DSYM_PATH" ]; then
    echo -e "${RED}Error: dSYMs not found at $DSYM_PATH${NC}"
    echo "Make sure you've built the app in Release mode first."
    exit 1
fi

# Find the upload script
UPLOAD_SCRIPT="${PODS_ROOT:-ios/Pods}/FirebaseCrashlytics/upload-symbols"

if [ ! -f "$UPLOAD_SCRIPT" ]; then
    # Try alternative location
    UPLOAD_SCRIPT="ios/Pods/FirebaseCrashlytics/upload-symbols"
fi

if [ ! -f "$UPLOAD_SCRIPT" ]; then
    echo -e "${RED}Error: Firebase Crashlytics upload script not found${NC}"
    echo "Make sure firebase_crashlytics is installed and you've run 'pod install'"
    exit 1
fi

# Find GoogleService-Info.plist
GOOGLE_SERVICE_INFO="${SRCROOT:-ios/Runner}/Runner/GoogleService-Info.plist"

if [ ! -f "$GOOGLE_SERVICE_INFO" ]; then
    GOOGLE_SERVICE_INFO="ios/Runner/GoogleService-Info.plist"
fi

if [ ! -f "$GOOGLE_SERVICE_INFO" ]; then
    echo -e "${RED}Error: GoogleService-Info.plist not found${NC}"
    exit 1
fi

# Upload dSYMs
echo "Uploading from: $DSYM_PATH"
"$UPLOAD_SCRIPT" -gsp "$GOOGLE_SERVICE_INFO" -p ios "$DSYM_PATH"

echo -e "${GREEN}dSYMs uploaded successfully!${NC}"
