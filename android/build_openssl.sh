#!/bin/bash
# Build OpenSSL 3.x for Android with 16KB page alignment support
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/openssl/${TARGET_ARCH}
NDK_PATH=/sources/android_ndk

# Clean previous build to avoid architecture conflicts
rm -rf /tmp/openssl
cp -r /sources/openssl /tmp/openssl

# Set up architecture-specific variables
if [ "$TARGET_ARCH" == "armeabi-v7a" ]
then
    TARGET=android-arm
    ANDROID_ARCH=arm
    export ARCH_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
    export ARCH_LINK="-march=armv7-a"
elif [ "$TARGET_ARCH" == "arm64-v8a" ]
then
    TARGET=android-arm64
    ANDROID_ARCH=arm64
    export ARCH_FLAGS=
    export ARCH_LINK=
elif [ "$TARGET_ARCH" == "x86" ]
then
    TARGET=android-x86
    ANDROID_ARCH=x86
    export ARCH_FLAGS="-march=i686 -msse3 -mstackrealign -mfpmath=sse"
    export ARCH_LINK=
elif [ "$TARGET_ARCH" == "x86_64" ]
then
    TARGET=android-x86_64
    ANDROID_ARCH=x86_64
    export ARCH_FLAGS=
    export ARCH_LINK=
else
    echo "Unsupported target ABI: $TARGET_ARCH"
    exit 1
fi

# Use NDK's prebuilt clang toolchain
export ANDROID_NDK_ROOT=${NDK_PATH}
export PATH="${NDK_PATH}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"

export CPPFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing "
export CXXFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -frtti -fexceptions "
export CFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing "
# 16KB page alignment for Android 15+ compatibility
export LDFLAGS=" ${ARCH_LINK} -Wl,-z,max-page-size=16384 "

cd /tmp/openssl/

# Configure OpenSSL 3.x for Android
./Configure ${TARGET} \
    -D__ANDROID_API__=${ANDROID_TARGET_API} \
    no-asm \
    no-shared \
    no-unit-test \
    --prefix=${TARGET_PATH} \
    --openssldir=${TARGET_PATH}

make clean || true
make -j$(nproc)
make install_sw

rm -rf /tmp/openssl/
