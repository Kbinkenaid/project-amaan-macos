#!/bin/bash

# Build script for macOS App
# This script builds the Swift Package and creates an app bundle

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="MacOSApp"
BUNDLE_ID="com.example.macosapp"
VERSION="1.0.0"
BUILD_CONFIG="release"
SWIFT_VERSION="5.9"

# Directories
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
DIST_DIR="${PROJECT_DIR}/dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"

echo -e "${BLUE}🚀 Building ${APP_NAME} v${VERSION}${NC}"
echo -e "${BLUE}Project Directory: ${PROJECT_DIR}${NC}"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf "${BUILD_DIR}"
rm -rf "${DIST_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${DIST_DIR}"

# Build the Swift package
echo -e "${YELLOW}🔨 Building Swift package...${NC}"
cd "${PROJECT_DIR}"
swift build --configuration ${BUILD_CONFIG} --build-path "${BUILD_DIR}"

# Check if build was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

# Create app bundle structure
echo -e "${YELLOW}📦 Creating app bundle...${NC}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
EXECUTABLE_PATH="${BUILD_DIR}/${BUILD_CONFIG}/${APP_NAME}"
if [ -f "${EXECUTABLE_PATH}" ]; then
    cp "${EXECUTABLE_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
    chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
else
    echo -e "${RED}❌ Executable not found at ${EXECUTABLE_PATH}${NC}"
    exit 1
fi

# Create Info.plist
echo -e "${YELLOW}📄 Creating Info.plist...${NC}"
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# Create a simple app icon (you can replace this with a proper icon)
echo -e "${YELLOW}🎨 Creating app icon...${NC}"
# This is a placeholder - in a real app, you'd have proper icon files
mkdir -p "${APP_BUNDLE}/Contents/Resources/AppIcon.iconset"

# Create entitlements file for sandboxing (optional)
echo -e "${YELLOW}🔒 Creating entitlements...${NC}"
cat > "${BUILD_DIR}/entitlements.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
EOF

# Code signing (if certificate is available)
echo -e "${YELLOW}✍️ Code signing...${NC}"
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo -e "${GREEN}📝 Code signing certificate found, signing app...${NC}"
    codesign --force --options runtime --entitlements "${BUILD_DIR}/entitlements.plist" --sign "Developer ID Application" "${APP_BUNDLE}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ App signed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️ Code signing failed, but continuing...${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ No code signing certificate found, skipping signing${NC}"
    echo -e "${YELLOW}   (App will run locally but cannot be distributed)${NC}"
fi

# Verify the app bundle
echo -e "${YELLOW}🔍 Verifying app bundle...${NC}"
if [ -d "${APP_BUNDLE}" ] && [ -f "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" ]; then
    echo -e "${GREEN}✅ App bundle created successfully!${NC}"
    echo -e "${GREEN}📍 Location: ${APP_BUNDLE}${NC}"
    
    # Show bundle size
    BUNDLE_SIZE=$(du -sh "${APP_BUNDLE}" | cut -f1)
    echo -e "${GREEN}📏 Bundle size: ${BUNDLE_SIZE}${NC}"
    
    # Create a symbolic link for easy access
    ln -sf "${APP_BUNDLE}" "${PROJECT_DIR}/MacOSApp.app"
    echo -e "${GREEN}🔗 Symbolic link created: ${PROJECT_DIR}/MacOSApp.app${NC}"
    
else
    echo -e "${RED}❌ App bundle creation failed!${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo -e "${GREEN}   You can now run: open ${APP_BUNDLE}${NC}"
echo -e "${GREEN}   Or double-click: ${PROJECT_DIR}/MacOSApp.app${NC}"