using namespace System.IO
using namespace System.Text
using namespace System.Text.RegularExpressions

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"

$projectRoot = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$cacheDir = "$projectRoot\cache"
$outputDir = "$projectRoot\output"

if ([Directory]::Exists($cacheDir)) {
    [Directory]::Delete($cacheDir, $true)
}
[Directory]::CreateDirectory($cacheDir) | Out-Null

if (-not [Directory]::Exists($outputDir)) {
    [Directory]::CreateDirectory($outputDir)
}

$xluaVersion = "v2.1.12"
Invoke-WebRequest -uri "https://github.com/Tencent/xLua/releases/download/$xluaVersion/xlua_${xluaVersion}.zip" -OutFile "$cacheDir\xlua_${xluaVersion}.zip"
if ([Directory]::Exists("$CacheDir\xlua")) {
    [Directory]::Delete("$CacheDir\xlua", $true)
}
[Directory]::CreateDirectory("$CacheDir\xlua") | Out-Null
Expand-Archive -Path "$cacheDir\xlua_${xluaVersion}.zip" -DestinationPath "$CacheDir\xlua"

$srcDir = "$CacheDir\xlua\Assets\XLua\Src"
[File]::Delete("$srcDir\CodeEmit.cs")
[File]::Delete("$srcDir\CodeEmit.cs.meta")

(Get-Content -Path "$srcDir\Editor\Generator.cs" -Raw).Replace('throw new InvalidOperationException("Code', '// throw new InvalidOperationException("Code') | Set-Content -Path "$srcDir\Editor\Generator.cs" -Encoding UTF8
(Get-Content -Path "$srcDir\ObjectTranslator.cs" -Raw).Replace("delegate_birdge_type =", "// delegate_birdge_type =") | Set-Content -Path "$srcDir\ObjectTranslator.cs" -Encoding UTF8
foreach ($file in [Directory]::GetFiles($srcDir, "*.cs", [SearchOption]::AllDirectories)) {
    [Regex]::Replace((Get-Content -Path $file -Raw), "([^!])UNITY_EDITOR", '$1NULL', [RegexOptions]::Multiline) | Set-Content -Path $file -Encoding UTF8
}

$content = @'
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

namespace XLua.LuaDLL
{
    public partial class Lua
    {
        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_pb(System.IntPtr L);

        [MonoPInvokeCallback(typeof(LuaDLL.lua_CSFunction))]
        public static int LoadLuaProfobuf(System.IntPtr L)
        {
            return luaopen_pb(L);
        }
    }
}
'@
[File]::WriteAllText("$srcDir\CustomLuaDLL.cs", $content, [Encoding]::UTF8)


if ([Directory]::Exists("$outputDir\Editor")) {
    [Directory]::Delete("$outputDir\Editor", $true)
}
[Directory]::Move("$srcDir\Editor", "$outputDir\Editor")

if ([Directory]::Exists("$outputDir\Scripts")) {
    [Directory]::Delete("$outputDir\Scripts", $true)
}
[Directory]::Move("$srcDir", "$outputDir\Scripts")

foreach ($file in [Directory]::GetFiles("$outputDir\Plugins", "*", [SearchOption]::AllDirectories)) {
    $meta = "$CacheDir\xlua\Assets\Plugins\" + [Uri]::new("$outputDir\Plugins\").MakeRelativeUri([Uri]::new($file)).ToString() + ".meta"
    if ([File]::Exists($meta)) {
        [File]::Move($meta, $file + ".meta")
    }
}

foreach ($dir in [Directory]::GetDirectories("$outputDir\Plugins", "*", [SearchOption]::AllDirectories)) {
    $meta = "$CacheDir\xlua\Assets\Plugins\" + [Uri]::new("$outputDir\Plugins\").MakeRelativeUri([Uri]::new($dir)).ToString() + ".meta"
    if ([File]::Exists($meta)) {
        [File]::Move($meta, $dir + ".meta")
    }
}