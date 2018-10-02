using namespace System.IO
using namespace System.Text
using namespace System.Text.RegularExpressions

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

try {
    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve

    $tempDir = "$projectRoot\temp"
    if ([Directory]::Exists($tempDir)) { [Directory]::Delete($tempDir, $true) }
    [Directory]::CreateDirectory($tempDir) | Out-Null
    $xluaBuildDir = "$projectRoot\dist\XLua"
    [Directory]::CreateDirectory($xluaBuildDir) | Out-Null

    $xluaSrcDir = "$tempDir\xLua-2.1.12"
    Invoke-WebRequest -Uri "https://github.com/Tencent/xLua/archive/v2.1.12.zip" -OutFile "$tempDir\v2.1.12.zip"
    Expand-Archive -Path "$tempDir\v2.1.12.zip" -DestinationPath $tempDir

    [Directory]::Move("$xluaSrcDir\Assets\XLua\Src\Editor", "$xluaBuildDir\Editor")
    (Get-Content -Path "$xluaBuildDir\Editor\Generator.cs" -Raw).Replace('throw new InvalidOperationException("Code', '// throw new InvalidOperationException("Code') | Set-Content -Path "$xluaBuildDir\Editor\Generator.cs" -Encoding UTF8

    [Directory]::Move("$xluaSrcDir\Assets\XLua\Src", "$xluaBuildDir\Scripts")
    [File]::Delete("$xluaBuildDir\Scripts\CodeEmit.cs")
    [File]::Delete("$xluaBuildDir\Scripts\CodeEmit.cs.meta")
    (Get-Content -Path "$xluaBuildDir\Scripts\ObjectTranslator.cs" -Raw).Replace("delegate_birdge_type =", "// delegate_birdge_type =") | Set-Content -Path "$xluaBuildDir\Scripts\ObjectTranslator.cs" -Encoding UTF8
    foreach ($file in [Directory]::GetFiles("$xluaBuildDir\Scripts", "*.cs", [SearchOption]::AllDirectories)) {
        [Regex]::Replace((Get-Content -Path $file -Raw), "([^!])UNITY_EDITOR", '$1NULL', [RegexOptions]::Multiline) | Set-Content -Path $file -Encoding UTF8
    }

    [File]::Copy("$xluaSrcDir\Assets\Plugins\iOS\libxlua.a.meta", "$xluaBuildDir\Plugins\iOS\os\libxlua.a.meta")
    [File]::Copy("$xluaSrcDir\Assets\Plugins\iOS\libxlua.a.meta", "$xluaBuildDir\Plugins\iOS\simulator~\libxlua.a.meta")
    [File]::Copy("$xluaSrcDir\Assets\Plugins\Android\libs\armeabi-v7a\libxlua.so.meta", "$xluaBuildDir\Plugins\Android\libs\armeabi-v7a\libxlua.so.meta")
    [File]::Copy("$xluaSrcDir\Assets\Plugins\Android\libs\x86\libxlua.so.meta", "$xluaBuildDir\Plugins\Android\libs\x86\libxlua.so.meta")
    [File]::Copy("$xluaSrcDir\Assets\Plugins\x86\xlua.dll.meta", "$xluaBuildDir\Plugins\x86\xlua.dll.meta")
    [File]::Copy("$xluaSrcDir\Assets\Plugins\x86_64\xlua.dll.meta", "$xluaBuildDir\Plugins\x86_64\xlua.dll.meta")

    Compress-Archive -Path $xluaBuildDir "$projectRoot\dist\XLua-2.1.12.0.zip"
}
catch {
    Write-Output $PSItem | Format-List -Force
    Read-Host
}