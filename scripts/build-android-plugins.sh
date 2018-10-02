#!/bin/sh

set -ex

project_root="$(cd "$(dirname "$0")/.." && pwd)" 
temp_dir="$project_root/temp"
build_dir="$project_root/build"

mkdir -p "$temp_dir" "$build_dir"

curl -L "https://cmake.org/files/v3.12/cmake-3.12.2-Linux-x86_64.tar.gz" | tar -zxf - -C "$temp_dir"
cmake_cmd="$temp_dir/cmake-3.12.2-Linux-x86_64/bin/cmake"

ndk_name="android-ndk-r10e-linux-x86_64"
curl -Lo "$temp_dir/$ndk_name.zip" "https://dl.google.com/android/repository/$ndk_name.zip"
7za x -o"$temp_dir" "$temp_dir/$ndk_name.zip"
export ANDROID_NDK="$temp_dir/android-ndk-r10e"

xlua_commit="68f9751c04341df317cd68db521b76e184ae4c94"
curl -Lo "$temp_dir/$xlua_commit.zip" "https://github.com/Tencent/xLua/archive/$xlua_commit.zip"
7za x -o"$temp_dir" "$temp_dir/$xlua_commit.zip"
xlua_src_dir="$temp_dir/xLua-$xlua_commit"

v7a_config_dir="$temp_dir/configs/armeabi-v7a"
v7a_build_dir="$build_dir/Plugins/Android/libs/armeabi-v7a"
mkdir -p "$v7a_config_dir" "$v7a_build_dir"
cd "$v7a_config_dir" && "$cmake_cmd" \
	-DANDROID_ABI="armeabi-v7a" \
	-DCMAKE_TOOLCHAIN_FILE="$xlua_src_dir/build/cmake/android.toolchain.cmake" \
	-DANDROID_TOOLCHAIN_NAME="arm-linux-androideabi-clang3.6" \
	-DANDROID_NATIVE_API_LEVEL="android-9" \
	"$xlua_src_dir/build"
"$cmake_cmd" --build "$v7a_config_dir" --config Release
mv "$v7a_config_dir/libxlua.so" "$v7a_build_dir/libxlua.so"

x86_config_dir="$temp_dir/configs/x86"
x86_build_dir="$build_dir/Plugins/Android/libs/x86"
mkdir -p "$x86_config_dir" "$x86_build_dir"
cd "$x86_config_dir" && "$cmake_cmd" \
	-DANDROID_ABI="x86" \
	-DCMAKE_TOOLCHAIN_FILE="$xlua_src_dir/build/cmake/android.toolchain.cmake" \
	-DANDROID_TOOLCHAIN_NAME="x86-clang3.5" \
	-DANDROID_NATIVE_API_LEVEL="android-9" \
	"$xlua_src_dir/build"
"$cmake_cmd" --build "$x86_config_dir" --config Release
mv "$x86_config_dir/libxlua.so" "$x86_build_dir/libxlua.so"
