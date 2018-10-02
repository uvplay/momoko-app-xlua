using namespace System.IO
using namespace System.Text

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

try {
    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
    $tempDir = "$projectRoot\temp"
    $buildDir = "$projectRoot\build"
    [Directory]::CreateDirectory($tempDir) | Out-Null
    [Directory]::CreateDirectory($buildDir) | Out-Null

    $uri = "https://cmake.org/files/v3.12/cmake-3.12.2-win64-x64.zip"
    Invoke-WebRequest -Uri $uri -OutFile "$tempDir\cmake-3.12.2-win64-x64.zip"
    Expand-Archive -Path "$tempDir\cmake-3.12.2-win64-x64.zip" -DestinationPath $tempDir
    $cmakeCmd = "$tempDir\cmake-3.12.2-win64-x64\bin\cmake.exe"

    Invoke-WebRequest -Uri "https://github.com/Tencent/xLua/archive/v2.1.12.zip" -OutFile "$tempDir\v2.1.12.zip"
    Expand-Archive -Path "$tempDir\v2.1.12.zip" -DestinationPath $tempDir
    $xLuaDir = "$tempDir\xLua-2.1.12"

    $x86ConfigDir = "$tempDir\configs\x86"
    $x86BuildDir = "$buildDir\Plugins\x86"
    [Directory]::CreateDirectory($x86ConfigDir) | Out-Null
    [Directory]::CreateDirectory($x86BuildDir) | Out-Null
    Set-Location -Path $x86ConfigDir
    & "$cmakeCmd" -G "Visual Studio 15 2017" "$xLuaDir\build"
    & "$cmakeCmd" --build $x86ConfigDir --config Release
    [File]::Move("$x86ConfigDir\Release\xlua.dll", "$x86BuildDir\xlua.dll")

    $x64ConfigDir = "$tempDir\configs\x86_64"
    $x64BuildDir = "$buildDir\Plugins\x86_64"
    [Directory]::CreateDirectory($x64ConfigDir) | Out-Null
    [Directory]::CreateDirectory($x64BuildDir) | Out-Null
    Set-Location -Path $x64ConfigDir
    & "$cmakeCmd" -G "Visual Studio 15 2017 Win64" "$xLuaDir\build"
    & "$cmakeCmd" --build $x64ConfigDir --config Release
    [File]::Move("$x64ConfigDir\Release\xlua.dll", "$x64BuildDir\xlua.dll")
}
catch {
    Write-Output $PSItem | Format-List -Force
    Read-Host
}