#!/bin/bash
set -e

VIALER_VERSION="3.5"
VIALER_ARCHIVE_URL="https://github.com/VoIPGRID/Vialer-pjsip-iOS/archive/${VIALER_VERSION}.zip"
VIALER_BINARY_URL="https://github.com/VoIPGRID/Vialer-pjsip-iOS/blob/${VIALER_VERSION}/VialerPJSIP.framework/Versions/A/VialerPJSIP?raw=true"

DEST="./dist/ios/VialerPJSIP.framework"
TMP="./dist/ios/.tmp"

rm -rf ./dist/ios
mkdir -p "$TMP"

echo "Downloading Vialer-pjsip-iOS ${VIALER_VERSION} archive..."
curl -L --silent "$VIALER_ARCHIVE_URL" -o "$TMP/vialer.zip"

echo "Downloading VialerPJSIP binary (git LFS)..."
curl -L --silent "$VIALER_BINARY_URL" -o "$TMP/VialerPJSIP"

echo "Extracting framework headers..."
unzip -q "$TMP/vialer.zip" -d "$TMP"

mkdir -p "$DEST"
cp -r "$TMP/Vialer-pjsip-iOS-${VIALER_VERSION}/VialerPJSIP.framework/Versions/Current/Headers" "$DEST/Headers"
cp "$TMP/VialerPJSIP" "$DEST/VialerPJSIP"

rm -rf "$TMP"
echo "iOS framework built at $DEST"
