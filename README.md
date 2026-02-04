# react-native-pjsip-builder

## Build for Android
- **PJSIP**: 2.14.1
- **NDK**: r27c
- **OpenSSL**: 3.0.13
- **OpenH264**: 2.4.1
- **Opus**: 1.5.2
- **Target API**: 24 (Android 7.0+)
- **16KB page alignment**: Supported (required for Android 15+)

### Supported Architectures
- armeabi-v7a (32-bit ARM)
- arm64-v8a (64-bit ARM)
- x86 (32-bit Intel)
- x86_64 (64-bit Intel)

## Build for iOS
#### pjsip 2.10

Provided by https://github.com/VoIPGRID/Vialer-pjsip-iOS

## PJSIP settings
- PJSUA_MAX_ACC = 8

## 16KB Page Alignment

Starting with Android 15, apps must support 16KB memory pages. All native libraries in this build include the `-Wl,-z,max-page-size=16384` linker flag to ensure compatibility.
