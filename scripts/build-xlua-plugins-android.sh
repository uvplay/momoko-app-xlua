#!/bin/sh

set -e

cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)
BUILD_DIR="$PROJECT_ROOT/builds"
CACHE_DIR="$PROJECT_ROOT/cache"
OUTPUT_DIR="$PROJECT_ROOT/output"

rm -rf "$CACHE_DIR" "$BUILD_DIR"

mkdir -p "$CACHE_DIR" "$BUILD_DIR" "$OUTPUT_DIR"

CMAKE_VERSION=3.12.0
CMAKE_VERSION_COMPACT=3.12
curl -Lo "$CACHE_DIR/cmake-$CMAKE_VERSION-Linux-x86_64.tar.gz" "https://cmake.org/files/v${CMAKE_VERSION_COMPACT}/cmake-$CMAKE_VERSION-Linux-x86_64.tar.gz"
tar -zxvf "$CACHE_DIR/cmake-$CMAKE_VERSION-Linux-x86_64.tar.gz" -C "$CACHE_DIR"
mv "$CACHE_DIR/cmake-$CMAKE_VERSION-Linux-x86_64" "$CACHE_DIR/cmake"

curl -Lo "$CACHE_DIR/android-ndk-r10e-linux-x86_64.zip" "https://dl.google.com/android/repository/android-ndk-r10e-linux-x86_64.zip"
7za x -o"$CACHE_DIR" "$CACHE_DIR/android-ndk-r10e-linux-x86_64.zip"
mv "$CACHE_DIR/android-ndk-r10e" "$CACHE_DIR/android-ndk"

XLUA_VERSION="48b6867060971714ff2c1148a43bd8a3121909af"
curl -Lo "$CACHE_DIR/$XLUA_VERSION.zip" "https://github.com/Tencent/xLua/archive/$XLUA_VERSION.zip"
7za x -o"$CACHE_DIR" "$CACHE_DIR/$XLUA_VERSION.zip"
rm -rf "$CACHE_DIR/xlua"
mv -f "$CACHE_DIR/xLua-$XLUA_VERSION" "$CACHE_DIR/xlua"


LUA_PROTOBUF_VERSION="106b9089a547acf38f2fc6c043f9c74e20cba0be"
curl -Lo "$CACHE_DIR/$LUA_PROTOBUF_VERSION.zip" "https://github.com/starwing/lua-protobuf/archive/$LUA_PROTOBUF_VERSION.zip"
7za x -o"$CACHE_DIR" "$CACHE_DIR/$LUA_PROTOBUF_VERSION.zip"
rm -rf "$CACHE_DIR/xlua/build/lua-protobuf"
mv -f "$CACHE_DIR/lua-protobuf-$LUA_PROTOBUF_VERSION" "$CACHE_DIR/xlua/build/lua-protobuf"

cat <<'EOF' >"$CACHE_DIR/list.txt"
set (LPB_SRC
    lua-protobuf/pb.c
)
set_property(
    SOURCE ${LPB_SRC}
    APPEND
    PROPERTY COMPILE_DEFINITIONS
    LUA_LIB
)
list(APPEND THIRDPART_INC lua-protobuf)
set (THIRDPART_SRC ${THIRDPART_SRC} ${LPB_SRC})

EOF

cat "$CACHE_DIR/list.txt" "$CACHE_DIR/xlua/build/CMakeLists.txt" >"$CACHE_DIR/CMakeLists.txt"
mv "$CACHE_DIR/CMakeLists.txt" "$CACHE_DIR/xlua/build/CMakeLists.txt"

export ANDROID_NDK="$CACHE_DIR/android-ndk"

mkdir -p "$BUILD_DIR/android/armeabi-v7a"
cd "$BUILD_DIR/android/armeabi-v7a"
"$CACHE_DIR/cmake/bin/cmake" \
	-DANDROID_ABI="armeabi-v7a" \
	-DCMAKE_TOOLCHAIN_FILE="$CACHE_DIR/xlua/build/cmake/android.toolchain.cmake" \
	-DANDROID_TOOLCHAIN_NAME="arm-linux-androideabi-clang3.6" \
	-DANDROID_NATIVE_API_LEVEL="android-9" \
	"$CACHE_DIR/xlua/build"
cd -
cmake --build "$BUILD_DIR/android/armeabi-v7a" --config Release
mkdir -p "$OUTPUT_DIR/Plugins/Android/libs/armeabi-v7a"
mv "$BUILD_DIR/android/armeabi-v7a/libxlua.so" "$OUTPUT_DIR/Plugins/Android/libs/armeabi-v7a/libxlua.so"

mkdir -p "$BUILD_DIR/android/x86"
cd "$BUILD_DIR/android/x86"
"$CACHE_DIR/cmake/bin/cmake" \
	-DANDROID_ABI="x86" \
	-DCMAKE_TOOLCHAIN_FILE="$CACHE_DIR/xlua/build/cmake/android.toolchain.cmake" \
	-DANDROID_TOOLCHAIN_NAME="x86-clang3.5" \
	-DANDROID_NATIVE_API_LEVEL="android-9" \
	"$CACHE_DIR/xlua/build"
cd -
cmake --build "$BUILD_DIR/android/x86" --config Release
mkdir -p "$OUTPUT_DIR/Plugins/Android/libs/x86"
mv "$BUILD_DIR/android/x86/libxlua.so" "$OUTPUT_DIR/Plugins/Android/libs/x86/libxlua.so"

rm -rf "$CACHE_DIR" "$BUILD_DIR"
