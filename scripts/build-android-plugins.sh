#!/bin/sh

set -ex

project_root="$(cd "$(dirname "$0")/.." && pwd)" 
temp_dir="$project_root/temp"
xlua_build_dir="$project_root/dist/XLua"
rm -rf "$temp_dir"
mkdir -p "$temp_dir" "$xlua_build_dir"

curl -sL "https://cmake.org/files/v3.12/cmake-3.12.2-Linux-x86_64.tar.gz" | tar -zxf - -C "$temp_dir"
cmake_cmd="$temp_dir/cmake-3.12.2-Linux-x86_64/bin/cmake"

curl -sLo "$temp_dir/android-ndk-r10e-linux-x86_64.zip" "https://dl.google.com/android/repository/android-ndk-r10e-linux-x86_64.zip"
unzip -oq "$temp_dir/android-ndk-r10e-linux-x86_64.zip" -d "$temp_dir"
export ANDROID_NDK="$temp_dir/android-ndk-r10e"

curl -sL "https://github.com/Tencent/xLua/archive/2.1.12.tar.gz" | tar -zxf - -C "$temp_dir"
xlua_src_dir="$temp_dir/xLua-2.1.12"

v7a_config_dir="$temp_dir/configs/armeabi-v7a"
v7a_xlua_build_dir="$xlua_build_dir/Plugins/Android/libs/armeabi-v7a"
mkdir -p "$v7a_config_dir" "$v7a_xlua_build_dir"
cd "$v7a_config_dir" && "$cmake_cmd" \
	-DANDROID_ABI="armeabi-v7a" \
	-DCMAKE_TOOLCHAIN_FILE="$xlua_src_dir/build/cmake/android.toolchain.cmake" \
	-DANDROID_TOOLCHAIN_NAME="arm-linux-androideabi-clang3.6" \
	-DANDROID_NATIVE_API_LEVEL="android-9" \
	"$xlua_src_dir/build"
"$cmake_cmd" --build "$v7a_config_dir" --config Release
mv "$v7a_config_dir/libxlua.so" "$v7a_xlua_build_dir/libxlua.so"

x86_config_dir="$temp_dir/configs/x86"
x86_xlua_build_dir="$xlua_build_dir/Plugins/Android/libs/x86"
mkdir -p "$x86_config_dir" "$x86_xlua_build_dir"
cd "$x86_config_dir" && "$cmake_cmd" \
	-DANDROID_ABI="x86" \
	-DCMAKE_TOOLCHAIN_FILE="$xlua_src_dir/build/cmake/android.toolchain.cmake" \
	-DANDROID_TOOLCHAIN_NAME="x86-clang3.5" \
	-DANDROID_NATIVE_API_LEVEL="android-9" \
	"$xlua_src_dir/build"
"$cmake_cmd" --build "$x86_config_dir" --config Release
mv "$x86_config_dir/libxlua.so" "$x86_xlua_build_dir/libxlua.so"
