#!/bin/sh

set -e

project_root="$(cd "$(dirname "$0")/.." && pwd)" 
temp_dir="$project_root/temp"
build_dir="$project_root/build"

curl -L "https://cmake.org/files/v3.12/cmake-3.12.2-Linux-x86_64.tar.gz" | tar -zxvf - -C "$temp_dir"
cmake_cmd="$temp_dir/cmake-3.12.2-Linux-x86_64"

ndk_name="android-ndk-r10e-linux-x86_64"
curl -L "$temp_dir/$ndk_name.zip" "https://dl.google.com/android/repository/$ndk_name.zip"
7za x -o"$temp_dir" "$temp_dir/$ndk_name.zip"
export ANDROID_NDK="$temp_dir/$ndk_name"

xlua_commit="68f9751c04341df317cd68db521b76e184ae4c94"
curl -Lo "$temp_dir/$xlua_commit.zip" "https://github.com/Tencent/xLua/archive/$xlua_commit.zip"
7za x -o"$temp_dir" "$temp_dir/$xlua_commit.zip"
xlua_src_dir="$temp_dir/xLua-$xlua_commit"

v7a_config_dir="$temp_dir/configs/armeabi-v7a"
mkdir -p "$v7a_config_dir" && cd "$_"
"$cmake_cmd" \
	-DANDROID_ABI="armeabi-v7a" \
	-DCMAKE_TOOLCHAIN_FILE="$xlua_src_dir/build/cmake/android.toolchain.cmake" \
	-DANDROID_TOOLCHAIN_NAME="arm-linux-androideabi-clang3.6" \
	-DANDROID_NATIVE_API_LEVEL="android-9" \
	"$xlua_src_dir/build"
"$cmake_cmd" --build "$v7a_config_dir" --config Release
mkdir -p "$build_dir/Plugins/Android/libs/armeabi-v7a" && mv "$v7a_config_dir/libxlua.so" "$_/libxlua.so"

x86_config_dir="$temp_dir/configs/x86"
mkdir -p "$x86_config_dir" && cd "$_"
"$CMAKE_CMD" \
	-DANDROID_ABI="x86" \
	-DCMAKE_TOOLCHAIN_FILE="$xlua_src_dir/build/cmake/android.toolchain.cmake" \
	-DANDROID_TOOLCHAIN_NAME="x86-clang3.5" \
	-DANDROID_NATIVE_API_LEVEL="android-9" \
	"$xlua_src_dir/build"
"$CMAKE_CMD" --build "$x86_config_dir" --config Release
mkdir -p "$build_dir/Plugins/Android/libs/x86" && mv "$x86_config_dir/libxlua.so" "$_/libxlua.so"