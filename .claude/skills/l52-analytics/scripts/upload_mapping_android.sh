#!/bin/bash
# Upload Android mapping files (ProGuard/R8) to error tracking service
#
# Usage:
#   ./upload_mapping_android.sh [crashlytics|sentry]
#
# This script is called from CI/CD after building a release APK/AAB.
#
# Prerequisites:
#   For Crashlytics:
#     - google-services.json in android/app/
#     - Firebase Crashlytics Gradle plugin configured
#     (Usually automatic - Gradle plugin handles upload)
#
#   For Sentry:
#     - sentry-cli installed
#     - SENTRY_AUTH_TOKEN, SENTRY_ORG, SENTRY_PROJECT env vars

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROVIDER="${1:-crashlytics}"

echo -e "${YELLOW}Uploading Android mapping files to $PROVIDER...${NC}"

# Find mapping file
MAPPING_FILE="build/app/outputs/mapping/release/mapping.txt"

if [ ! -f "$MAPPING_FILE" ]; then
    # Try alternative paths
    MAPPING_FILE="android/app/build/outputs/mapping/release/mapping.txt"
fi

if [ ! -f "$MAPPING_FILE" ]; then
    echo -e "${YELLOW}Warning: mapping.txt not found${NC}"
    echo "This is normal if minifyEnabled is false or this is a debug build."
    exit 0
fi

case "$PROVIDER" in
    crashlytics)
        echo "Firebase Crashlytics mapping upload is handled automatically by Gradle plugin."
        echo "Ensure your android/app/build.gradle.kts has:"
        echo "  firebaseCrashlytics { mappingFileUploadEnabled = true }"
        echo ""
        echo "If building via CI, run:"
        echo "  ./gradlew assembleRelease crashlyticsUploadSymbolsRelease"
        ;;

    sentry)
        # Check for sentry-cli
        if ! command -v sentry-cli &> /dev/null; then
            echo -e "${RED}Error: sentry-cli not found${NC}"
            echo "Install with: brew install getsentry/tools/sentry-cli"
            exit 1
        fi

        # Check required environment variables
        if [ -z "$SENTRY_AUTH_TOKEN" ] || [ -z "$SENTRY_ORG" ] || [ -z "$SENTRY_PROJECT" ]; then
            echo -e "${RED}Error: SENTRY_AUTH_TOKEN, SENTRY_ORG, SENTRY_PROJECT must be set${NC}"
            exit 1
        fi

        # Get version info
        VERSION_NAME=$(grep "versionName" android/app/build.gradle.kts | head -1 | sed 's/.*"\(.*\)".*/\1/')
        VERSION_CODE=$(grep "versionCode" android/app/build.gradle.kts | head -1 | sed 's/[^0-9]*//g')

        echo "Uploading mapping for version $VERSION_NAME ($VERSION_CODE)"

        sentry-cli upload-proguard \
            --org "$SENTRY_ORG" \
            --project "$SENTRY_PROJECT" \
            --version "$VERSION_NAME" \
            --version-code "$VERSION_CODE" \
            "$MAPPING_FILE"

        echo -e "${GREEN}Android mapping file uploaded to Sentry!${NC}"
        ;;

    *)
        echo -e "${RED}Unknown provider: $PROVIDER${NC}"
        echo "Usage: $0 [crashlytics|sentry]"
        exit 1
        ;;
esac
