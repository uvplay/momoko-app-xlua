using namespace System.IO
using namespace System.Text

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

try {
    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
    $tempDir = "$projectRoot\temp"
    if ([Directory]::Exists($tempDir)) { [Directory]::Delete($tempDir, $true) }
    [Directory]::CreateDirectory($tempDir) | Out-Null
    $xluaBuildDir = "$projectRoot\dist\XLua"
    [Directory]::CreateDirectory($xluaBuildDir) | Out-Null

    $cmakeDir = "$tempDir\cmake-3.12.2-win64-x64"
    Invoke-WebRequest -Uri "https://cmake.org/files/v3.12/cmake-3.12.2-win64-x64.zip" -OutFile "$tempDir\cmake-3.12.2-win64-x64.zip"
    Expand-Archive -Path "$tempDir\cmake-3.12.2-win64-x64.zip" -DestinationPath $tempDir
    $cmakeCmd = "$cmakeDir\bin\cmake.exe"

    $xluaSrcDir = "$tempDir\xLua-2.1.12"
    Invoke-WebRequest -Uri "https://github.com/Tencent/xLua/archive/v2.1.12.zip" -OutFile "$tempDir\v2.1.12.zip"
    Expand-Archive -Path "$tempDir\v2.1.12.zip" -DestinationPath $tempDir

    $x86ConfigDir = "$tempDir\configs\x86"
    [Directory]::CreateDirectory($x86ConfigDir) | Out-Null
    $x86BuildDir = "$xluaBuildDir\Plugins\x86"
    [Directory]::CreateDirectory($x86BuildDir) | Out-Null
    Set-Location -Path $x86ConfigDir
    & "$cmakeCmd" -G "Visual Studio 15 2017" "$xluaSrcDir\build"
    & "$cmakeCmd" --build $x86ConfigDir --config Release
    [File]::Move("$x86ConfigDir\Release\xlua.dll", "$x86BuildDir\xlua.dll")

    $x64ConfigDir = "$tempDir\configs\x86_64"
    [Directory]::CreateDirectory($x64ConfigDir) | Out-Null
    $x64BuildDir = "$xluaBuildDir\Plugins\x86_64"
    [Directory]::CreateDirectory($x64BuildDir) | Out-Null
    Set-Location -Path $x64ConfigDir
    & "$cmakeCmd" -G "Visual Studio 15 2017 Win64" "$xluaSrcDir\build"
    & "$cmakeCmd" --build $x64ConfigDir --config Release
    [File]::Move("$x64ConfigDir\Release\xlua.dll", "$x64BuildDir\xlua.dll")
}
catch {
    Write-Output $PSItem | Format-List -Force
    Read-Host
}