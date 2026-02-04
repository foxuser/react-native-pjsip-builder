#!/bin/bash
# Build OpenH264 for Android with 16KB page alignment support
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/openh264/${TARGET_ARCH}

# Clean previous build to avoid architecture conflicts
rm -rf /tmp/openh264
cp -r /sources/openh264 /tmp/openh264
cd /tmp/openh264

sed -i "s*PREFIX=/usr/local*PREFIX=${TARGET_PATH}*g" Makefile

# 16KB page alignment for Android 15+ compatibility
export LDFLAGS="-Wl,-z,max-page-size=16384"

ARGS="OS=android ENABLEPIC=Yes NDKROOT=/sources/android_ndk NDKLEVEL=${OPENH264_TARGET_NDK_LEVEL} "
ARGS="${ARGS}TARGET=android-${ANDROID_TARGET_API} ARCH="

if [ "$TARGET_ARCH" == "armeabi-v7a" ]
then
    ARGS="${ARGS}arm"
elif [ "$TARGET_ARCH" == "x86" ]
then
    ARGS="${ARGS}x86"
elif [ "$TARGET_ARCH" == "x86_64" ]
then
    ARGS="${ARGS}x86_64"
elif [ "$TARGET_ARCH" == "arm64-v8a" ]
then
    ARGS="${ARGS}arm64"
fi

# Pass LDFLAGS for 16KB page alignment
ARGS="${ARGS} LDFLAGS=\"${LDFLAGS}\""

make ${ARGS} install

rm -rf /tmp/openh264