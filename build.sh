#!/bin/bash

# Music Stream iOS App - Build Script for AltStore
# This script builds the iOS app and creates an IPA file

set -e

echo "🎵 Building Music Stream iOS App for AltStore"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="MusicStream"
BUNDLE_ID="com.musicstream.app"
SCHEME="MusicStream"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
IPA_PATH="${BUILD_DIR}/${APP_NAME}.ipa"
EXPORT_OPTIONS="ExportOptions.plist"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed${NC}"
    echo "Please install Xcode from the Mac App Store"
    exit 1
fi

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}Warning: This script is designed to run on macOS${NC}"
    echo "For cross-platform building, see README.md for alternative methods"
fi

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Check if project.pbxproj exists, if not generate it with XcodeGen
if [ ! -d "${APP_NAME}.xcodeproj" ]; then
    echo -e "${YELLOW}Generating Xcode project...${NC}"
    
    if command -v xcodegen &> /dev/null; then
        xcodegen generate
    else
        echo -e "${YELLOW}XcodeGen not found. Installing via Homebrew...${NC}"
        if command -v brew &> /dev/null; then
            brew install xcodegen
            xcodegen generate
        else
            echo -e "${RED}Error: Homebrew not found. Please install XcodeGen manually${NC}"
            echo "Visit: https://github.com/yonaskolb/XcodeGen"
            exit 1
        fi
    fi
fi

# Build the archive
echo -e "${YELLOW}Building archive...${NC}"
xcodebuild archive \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -archivePath "${ARCHIVE_PATH}" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Export IPA
echo -e "${YELLOW}Exporting IPA...${NC}"
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${BUILD_DIR}" \
    -exportOptionsPlist "${EXPORT_OPTIONS}"

# Check if IPA was created
if [ -f "${IPA_PATH}" ]; then
    echo -e "${GREEN}✅ Success! IPA created at: ${IPA_PATH}${NC}"
    echo -e "${GREEN}File size: $(du -h "${IPA_PATH}" | cut -f1)${NC}"
    echo ""
    echo -e "${GREEN}📱 You can now install this IPA using:${NC}"
    echo "   • AltStore on iOS devices"
    echo "   • Sideloadly"
    echo "   • Any IPA installer tool"
else
    echo -e "${RED}❌ Error: IPA file was not created${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Build complete! 🎉${NC}"

