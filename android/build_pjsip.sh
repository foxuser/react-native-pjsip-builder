#!/bin/bash
# Build PJSIP for Android with 16KB page alignment support
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/pjsip/${TARGET_ARCH}

# Clean previous build to avoid architecture conflicts
rm -rf /tmp/pjsip
cp -r /sources/pjsip /tmp/pjsip

# PJSIP configuration
cat <<EOF > "/tmp/pjsip/pjlib/include/pj/config_site.h"
#define PJ_CONFIG_ANDROID 1
#define PJMEDIA_HAS_G729_CODEC 1
#define PJMEDIA_HAS_G7221_CODEC 1
#include <pj/config_site_sample.h>
#define PJMEDIA_HAS_VIDEO 1
#define PJMEDIA_AUDIO_DEV_HAS_ANDROID_JNI 0
#define PJMEDIA_AUDIO_DEV_HAS_OPENSL 1
#define PJSIP_AUTH_AUTO_SEND_NEXT 0
EOF

cd /tmp/pjsip

export TARGET_ABI=${TARGET_ARCH}
export APP_PLATFORM=android-${ANDROID_TARGET_API}
export ANDROID_NDK_ROOT=/sources/android_ndk

# 16KB page alignment for Android 15+ compatibility
export LDFLAGS="-Wl,-z,max-page-size=16384"
export CFLAGS="-fPIC"
export CXXFLAGS="-fPIC"

./configure-android \
    --use-ndk-cflags \
    --with-ssl="/output/openssl/${TARGET_ARCH}" \
    --with-openh264="/output/openh264/${TARGET_ARCH}" \
    --with-opus="/output/opus/${TARGET_ARCH}"

make dep
make

cd /tmp/pjsip/pjsip-apps/src/swig
# Clean previous architecture build artifacts to avoid incompatible object files
make clean || true
make

mkdir -p /output/pjsip/jniLibs/${TARGET_ARCH}/

# PJSIP 2.14+ uses different output path
if [ -f "./java/android/pjsua2/src/main/jniLibs/${TARGET_ARCH}/libpjsua2.so" ]; then
  mv ./java/android/pjsua2/src/main/jniLibs/${TARGET_ARCH}/libpjsua2.so /output/pjsip/jniLibs/${TARGET_ARCH}/
elif [ -f "./java/android/app/src/main/jniLibs/${TARGET_ARCH}/libpjsua2.so" ]; then
  mv ./java/android/app/src/main/jniLibs/${TARGET_ARCH}/libpjsua2.so /output/pjsip/jniLibs/${TARGET_ARCH}/
else
  echo "ERROR: libpjsua2.so not found for ${TARGET_ARCH}"
  find ./java -name "libpjsua2.so" 2>/dev/null
  exit 1
fi

if [ ! -d "/output/pjsip/java" ]; then
  # PJSIP 2.14+ uses different java output path
  if [ -d "./java/android/pjsua2/src/main/java" ]; then
    mv ./java/android/pjsua2/src/main/java /output/pjsip/java
  elif [ -d "./java/android/app/src/main/java" ]; then
    mv ./java/android/app/src/main/java /output/pjsip/java
  fi
fi

rm -rf /tmp/pjsip
