FROM ubuntu:latest

##############################
# Download dependencies
##############################

RUN dpkg --add-architecture i386 && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    software-properties-common git curl bzip2 gcc g++ binutils make autoconf automake libtool openssl \
    libssl-dev ant libopus0 libpcre3 libpcre3-dev build-essential nasm libc6:i386 libstdc++6:i386 zlib1g:i386 \
    openjdk-8-jdk unzip pkg-config

##############################
# Configuration
##############################

# Target architectures
ENV TARGET_ARCHS="armeabi-v7a x86 arm64-v8a x86_64"

# NDK r27c required for 16KB page alignment support
ENV ANDROID_NDK_DOWNLOAD_URL="https://dl.google.com/android/repository/android-ndk-r27c-linux.zip"
ENV ANDROID_SDK_DOWNLOAD_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
ENV ANDROID_SETUP_APIS="24 34"
ENV ANDROID_BUILD_TOOLS_VERSION=34
ENV ANDROID_TARGET_API=24

# Updated dependency versions
ENV PJSIP_DOWNLOAD_URL="https://github.com/pjsip/pjproject/archive/refs/tags/2.14.1.tar.gz"
ENV SWIG_DOWNLOAD_URL="https://github.com/swig/swig/archive/refs/tags/v4.2.1.tar.gz"
ENV OPENSSL_DOWNLOAD_URL="https://www.openssl.org/source/openssl-3.0.13.tar.gz"
ENV OPENH264_DOWNLOAD_URL="https://github.com/cisco/openh264/archive/v2.4.1.tar.gz"
ENV OPENH264_TARGET_NDK_LEVEL=24
ENV OPUS_DOWNLOAD_URL="https://downloads.xiph.org/releases/opus/opus-1.5.2.tar.gz"

# 16KB page alignment linker flag (required for Android 15+)
ENV PAGE_SIZE_LDFLAGS="-Wl,-z,max-page-size=16384"

# Set PATH to include NDK and local scripts
ENV PATH="/usr/local/sbin:/sources/android_ndk:${PATH}"

##############################
# Download sources
##############################

RUN mkdir -p /sources/android_ndk && \
    mkdir -p /sources/android_sdk && \
    mkdir -p /sources/pjsip && \
    mkdir -p /sources/swig && \
    mkdir -p /sources/openssl && \
    mkdir -p /sources/opus && \
    mkdir -p /sources/openh264

# Download Android NDK (r27c with 16KB page support)
RUN cd /sources/android_ndk && \
    curl -L -# -o ndk.zip "$ANDROID_NDK_DOWNLOAD_URL" && \
    unzip ndk.zip && \
    rm -rf ndk.zip && \
    mv android-ndk-*/* ./ || true

# Download Android SDK & APIs using modern command line tools
RUN cd /sources/android_sdk && \
    curl -L -# -o sdk.zip "$ANDROID_SDK_DOWNLOAD_URL" && \
    unzip sdk.zip && \
    mkdir -p cmdline-tools/latest && \
    mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || mv bin lib cmdline-tools/latest/ 2>/dev/null || true

ENV ANDROID_SDK_ROOT="/sources/android_sdk"
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}"

RUN yes | sdkmanager --licenses || true && \
    sdkmanager "platforms;android-24" "platforms;android-34" "build-tools;34.0.0" "platform-tools"

# Download Pjsip
RUN cd /sources/pjsip && \
    curl -L -# -o pjsip.tar.gz "$PJSIP_DOWNLOAD_URL" && \
    tar xzf pjsip.tar.gz && \
    rm -rf pjsip.tar.gz && \
    mv pjproject-*/* ./

# Download Swig
RUN cd /sources/swig && \
    curl -L -# -o swig.tar.gz "$SWIG_DOWNLOAD_URL" && \
    tar xzf swig.tar.gz && \
    rm -rf swig.tar.gz && \
    mv swig-*/* ./

# Download OpenSSL
RUN cd /sources/openssl && \
    curl -L -# -o openssl.tar.gz "$OPENSSL_DOWNLOAD_URL" && \
    tar xzf openssl.tar.gz && \
    rm -rf openssl.tar.gz && \
    mv openssl-*/* ./

# Download Opus
RUN cd /sources/opus && \
    curl -L -# -o opus.tar.gz "$OPUS_DOWNLOAD_URL" && \
    tar xzf opus.tar.gz && \
    rm -rf opus.tar.gz && \
    mv opus-*/* ./

# Download OpenH264
RUN cd /sources/openh264 && \
    curl -L -# -o openh264.tar.gz "$OPENH264_DOWNLOAD_URL" && \
    tar xzf openh264.tar.gz && \
    rm -rf openh264.tar.gz && \
    mv openh264-*/* ./

##############################
# Build swig, openssl, opus, openh264
##############################

RUN mkdir -p /output/openssl/ && \
    mkdir -p /output/openh264/ && \
    mkdir -p /output/pjsip && \
    mkdir -p /output/opus

# Copy and make build scripts executable (fix Windows line endings)
COPY ./build_opus.sh /usr/local/sbin/
COPY ./build_openh264.sh /usr/local/sbin/
COPY ./build_openssl.sh /usr/local/sbin/
COPY ./build_pjsip.sh /usr/local/sbin/
RUN apt-get update && apt-get install -y dos2unix && \
    dos2unix /usr/local/sbin/build_*.sh && \
    chmod +x /usr/local/sbin/build_*.sh

# Build opus
RUN for arch in $TARGET_ARCHS; do \
      /usr/local/sbin/build_opus.sh ${arch}; \
    done

# Build swig (requires autoreconf for GitHub release)
RUN cd /sources/swig && \
    apt-get update && apt-get install -y automake autoconf libtool libpcre2-dev bison && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

# Build OpenH264
RUN for arch in $TARGET_ARCHS; do \
      /usr/local/sbin/build_openh264.sh ${arch}; \
    done

# Build openssl
RUN for arch in $TARGET_ARCHS; do \
      /usr/local/sbin/build_openssl.sh ${arch}; \
    done

# Build pjsip
RUN for arch in $TARGET_ARCHS; do \
      /usr/local/sbin/build_pjsip.sh ${arch}; \
    done

# Dist
RUN mkdir -p /dist/android/src/main && \
    mv /output/pjsip/* /dist/android/src/main && \
    rm -rf /dist/android/src/main/java/org/pjsip/pjsua2/app

RUN for arch in $TARGET_ARCHS; do \
      mv /output/openh264/${arch}/lib/libopenh264.so /dist/android/src/main/jniLibs/${arch}/; \
    done

# Copy libc++_shared.so from NDK for each architecture
RUN for arch in $TARGET_ARCHS; do \
      case $arch in \
        armeabi-v7a) NDK_ARCH="arm-linux-androideabi" ;; \
        arm64-v8a) NDK_ARCH="aarch64-linux-android" ;; \
        x86) NDK_ARCH="i686-linux-android" ;; \
        x86_64) NDK_ARCH="x86_64-linux-android" ;; \
      esac; \
      cp /sources/android_ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${NDK_ARCH}/libc++_shared.so \
         /dist/android/src/main/jniLibs/${arch}/; \
    done
