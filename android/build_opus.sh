#!/bin/bash
# Build Opus for Android with 16KB page alignment support
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/opus/${TARGET_ARCH}
NDK_PATH=/sources/android_ndk

# Clean previous build to avoid architecture conflicts
rm -rf /tmp/opus
cp -r /sources/opus /tmp/opus
cd /tmp/opus

# Set up toolchain based on architecture
case "$TARGET_ARCH" in
    armeabi-v7a)
        HOST=armv7a-linux-androideabi
        TOOLCHAIN_PREFIX=armv7a-linux-androideabi
        ;;
    arm64-v8a)
        HOST=aarch64-linux-android
        TOOLCHAIN_PREFIX=aarch64-linux-android
        ;;
    x86)
        HOST=i686-linux-android
        TOOLCHAIN_PREFIX=i686-linux-android
        ;;
    x86_64)
        HOST=x86_64-linux-android
        TOOLCHAIN_PREFIX=x86_64-linux-android
        ;;
    *)
        echo "Unsupported architecture: $TARGET_ARCH"
        exit 1
        ;;
esac

# Set up NDK toolchain
TOOLCHAIN=${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64
export PATH=${TOOLCHAIN}/bin:$PATH
export CC=${TOOLCHAIN_PREFIX}${ANDROID_TARGET_API}-clang
export CXX=${TOOLCHAIN_PREFIX}${ANDROID_TARGET_API}-clang++
export AR=llvm-ar
export AS=llvm-as
export LD=ld
export RANLIB=llvm-ranlib
export STRIP=llvm-strip

# 16KB page alignment for Android 15+ compatibility
export CFLAGS="-fPIC"
export CXXFLAGS="-fPIC"
export LDFLAGS="-Wl,-z,max-page-size=16384"

# Configure and build
./autogen.sh || true
./configure \
    --host=${HOST} \
    --prefix=${TARGET_PATH} \
    --disable-shared \
    --enable-static \
    --disable-doc \
    --disable-extra-programs

make clean || true
make -j$(nproc)
make install

rm -rf /tmp/opus
