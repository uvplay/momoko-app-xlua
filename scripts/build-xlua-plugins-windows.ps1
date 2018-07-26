using namespace System.IO
using namespace System.Text

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"

$projectRoot = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$cacheDir = "$projectRoot\cache"
$buildDir = "$projectRoot\builds"
$outputDir = "$projectRoot\output"

$cmakeVersion = "3.12.0"
$xluaVersion = "48b6867060971714ff2c1148a43bd8a3121909af"
$luapbVersion = "106b9089a547acf38f2fc6c043f9c74e20cba0be"

try {
    foreach ($dir in $cacheDir, $buildDir, $outputDir) {
        if ([Directory]::Exists($dir)) {
            [Directory]::Delete($dir, $true)
        }
        [Directory]::CreateDirectory($dir) | Out-Null
    }

    # [CMake](https://cmake.org/download/)
    $cmakeVersion = "3.12.0"
    $uri = "https://cmake.org/files/v$($cmakeVersion.Substring(0, $cmakeVersion.LastIndexOf('.')))/cmake-$cmakeVersion-win64-x64.zip"
    Invoke-WebRequest -Uri $uri -OutFile "$cacheDir\cmake-$cmakeVersion-win64-x64.zip"
    Expand-Archive -Path "$cacheDir\cmake-$cmakeVersion-win64-x64.zip" -DestinationPath $cacheDir
    [Directory]::Move("$cacheDir\cmake-$cmakeVersion-win64-x64", "$cacheDir\cmake")

    # https://github.com/Tencent/xLua
    $uri = "https://github.com/Tencent/xLua/archive/$xluaVersion.zip"
    Invoke-WebRequest -Uri $uri -OutFile "$cacheDir\xLua-$xluaVersion.zip"
    Expand-Archive -Path "$cacheDir\xLua-$xluaVersion.zip" -DestinationPath $cacheDir
    [Directory]::Move("$cacheDir\xLua-$xluaVersion", "$cacheDir\xlua")

    # https://github.com/starwing/lua-protobuf
    $uri = "https://github.com/starwing/lua-protobuf/archive/$luapbVersion.zip"
    Invoke-WebRequest -Uri $uri -OutFile "$cacheDir\lua-protobuf-$luapbVersion.zip"
    Expand-Archive -Path "$cacheDir\lua-protobuf-$luapbVersion.zip" -DestinationPath $cacheDir
    [Directory]::Move("$cacheDir\lua-protobuf-$luapbVersion", "$cacheDir\xlua\build\lua-protobuf")

    $listFile = "$cacheDir\xLua\build\CMakeLists.txt"
    $content = @'
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
'@ + "`r`n`r`n"
    $content += [File]::ReadAllText($listFile)
    [File]::WriteAllText($listFile, $content, [Encoding]::UTF8)

    [Directory]::CreateDirectory("$buildDir\windows\x86_64") | Out-Null
    Push-Location -Path "$buildDir\windows\x86_64"
    & "$cacheDir\cmake\bin\cmake.exe" -G "Visual Studio 15 2017 Win64" "$cacheDir\xlua\build"
    Pop-Location
    & "$cacheDir\cmake\bin\cmake.exe" --build "$buildDir\windows\x86_64" --config Release

    [Directory]::CreateDirectory("$outputDir\Plugins\x86_64")
    [File]::Move("$buildDir\windows\x86_64\Release\xlua.dll", "$outputDir\Plugins\x86_64\xlua.dll")

    [Directory]::CreateDirectory("$buildDir\windows\x86") | Out-Null
    Push-Location -Path "$buildDir\windows\x86"
    & "$cacheDir\cmake\bin\cmake.exe" -G "Visual Studio 15 2017" "$cacheDir\xlua\build"
    Pop-Location
    & "$cacheDir\cmake\bin\cmake.exe" --build "$buildDir\windows\x86" --config Release
    [Directory]::CreateDirectory("$outputDir\Plugins\x86")
    [File]::Move("$buildDir\windows\x86\Release\xlua.dll", "$outputDir\Plugins\x86\xlua.dll")
}
catch {
    Write-Output $PSItem | Format-List -Force
    Read-Host
}