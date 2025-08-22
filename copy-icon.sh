#!/bin/bash

# Copy icon to app bundle after build
APP_BUNDLE="${BUILT_PRODUCTS_DIR}/Proofreader.app"
ICON_SOURCE="${PROJECT_DIR}/Resources/AppIcon.icns"

if [ -d "$APP_BUNDLE" ] && [ -f "$ICON_SOURCE" ]; then
    mkdir -p "${APP_BUNDLE}/Contents/Resources"
    cp "$ICON_SOURCE" "${APP_BUNDLE}/Contents/Resources/"
    echo "Icon copied to app bundle"
else
    echo "Warning: Could not copy icon - app bundle or icon not found"
fi