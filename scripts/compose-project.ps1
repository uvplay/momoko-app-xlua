using namespace System.IO
using namespace System.Text
using namespace System.Text.RegularExpressions

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"

$projectRoot = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$tempDir = "$projectRoot\temp"
$buildDir = "$projectRoot\build"

[Directory]::CreateDirectory($tempDir) | Out-Null
[Directory]::CreateDirectory($buildDir) | Out-Null

$xLuaVersion = "v2.1.12"
$xLuaDir = "$tempDir\xlua_${xLuaVersion}"
[Directory]::CreateDirectory($xLuaDir) | Out-Null
Invoke-WebRequest -uri "https://github.com/Tencent/xLua/releases/download/$xLuaVersion/xlua_${xLuaVersion}.zip" -OutFile "$tempDir\xlua_${xLuaVersion}.zip"
Expand-Archive -Path "$tempDir\xlua_${xLuaVersion}.zip" -DestinationPath $xLuaDir

$srcDir = "$xLuaDir\Assets\XLua\Src"
[File]::Delete("$srcDir\CodeEmit.cs")
[File]::Delete("$srcDir\CodeEmit.cs.meta")

(Get-Content -Path "$srcDir\Editor\Generator.cs" -Raw).Replace('throw new InvalidOperationException("Code', '// throw new InvalidOperationException("Code') | Set-Content -Path "$srcDir\Editor\Generator.cs" -Encoding UTF8
(Get-Content -Path "$srcDir\ObjectTranslator.cs" -Raw).Replace("delegate_birdge_type =", "// delegate_birdge_type =") | Set-Content -Path "$srcDir\ObjectTranslator.cs" -Encoding UTF8
foreach ($file in [Directory]::GetFiles($srcDir, "*.cs", [SearchOption]::AllDirectories)) {
    [Regex]::Replace((Get-Content -Path $file -Raw), "([^!])UNITY_EDITOR", '$1NULL', [RegexOptions]::Multiline) | Set-Content -Path $file -Encoding UTF8
}

if ([Directory]::Exists("$buildDir\Editor")) {
    [Directory]::Delete("$buildDir\Editor", $true)
}
[Directory]::Move("$srcDir\Editor", "$buildDir\Editor")

if ([Directory]::Exists("$buildDir\Scripts")) {
    [Directory]::Delete("$buildDir\Scripts", $true)
}
[Directory]::Move("$srcDir", "$buildDir\Scripts")

foreach ($file in [Directory]::GetFiles("$buildDir\Plugins", "*", [SearchOption]::AllDirectories)) {
    $meta = "$tempDir\xlua\Assets\Plugins\" + [Uri]::new("$buildDir\Plugins\").MakeRelativeUri([Uri]::new($file)).ToString() + ".meta"
    if ([File]::Exists($meta)) {
        [File]::Move($meta, $file + ".meta")
    }
}

foreach ($dir in [Directory]::GetDirectories("$buildDir\Plugins", "*", [SearchOption]::AllDirectories)) {
    $meta = "$tempDir\xlua\Assets\Plugins\" + [Uri]::new("$buildDir\Plugins\").MakeRelativeUri([Uri]::new($dir)).ToString() + ".meta"
    if ([File]::Exists($meta)) {
        [File]::Move($meta, $dir + ".meta")
    }
}