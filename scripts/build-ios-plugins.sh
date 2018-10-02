#!/bin/sh

set -ex

project_root="$(cd "$(dirname "$0")/.." && pwd)" 
temp_dir="$project_root/temp"
build_dir="$project_root/build"

mkdir -p "$temp_dir" "$build_dir"

curl -sL "https://cmake.org/files/v3.12/cmake-3.12.2-Darwin-x86_64.tar.gz" | tar -zxf - -C "$temp_dir"
cmake_cmd="$temp_dir/cmake-3.12.2-Darwin-x86_64/CMake.app/Contents/bin/cmake"

xlua_commit="68f9751c04341df317cd68db521b76e184ae4c94"
curl -sLo "$temp_dir/$xlua_commit.zip" "https://github.com/Tencent/xLua/archive/$xlua_commit.zip"
unzip -o "$temp_dir/$xlua_commit.zip" -d "$temp_dir" 
xlua_src_dir="$temp_dir/xLua-$xlua_commit"

os_config_dir="$temp_dir/configs/os"
os_build_dir="$build_dir/Plugins/iOS"
mkdir -p "$os_config_dir" "$os_build_dir"
cd "$os_config_dir" && "$cmake_cmd" \
	-DCMAKE_TOOLCHAIN_FILE="$xlua_src_dir/build/cmake/iOS.cmake" \
	-GXcode \
	"$xlua_src_dir/build"
"$cmake_cmd" --build "$os_config_dir" --config Release
mv "$os_config_dir/Release-iphoneos/libxlua.a" "$os_build_dir/libxlua.a"

simulator_config_dir="$temp_dir/configs/simulator"
simulator_build_dir="$build_dir/Plugins/iOS/simulator"
mkdir -p "$simulator_config_dir" "$simulator_build_dir"
cd "$simulator_config_dir" && "$cmake_cmd" \
	-DIOS_PLATFORM=SIMULATOR \
	-DCMAKE_TOOLCHAIN_FILE="$xlua_src_dir/build/cmake/iOS.cmake" \
	-GXcode \
	"$xlua_src_dir/build"
"$cmake_cmd" --build "$simulator_config_dir" --config Release
mv "$simulator_config_dir/Release-iphonesimulator/libxlua.a" "$simulator_build_dir/libxlua.a"