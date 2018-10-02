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

    foreach ($srcMeta in [Directory]::GetFiles("$xluaSrcDir\Assets\Plugins", "*.meta", [SearchOption]::AllDirectories)) {
        $dstMeta = "$xluaBuildDir\Plugins\" + ([Uri]::new("$xluaSrcDir\Assets\Plugins\")).MakeRelativeUri([Uri]::new($srcMeta)).ToString()
        $dstFile = $dstMeta.Substring(0, $dstMeta.LastIndexOf("."))
        if ([File]::Exists($dstFile) -or [Directory]::Exists($dstFile)) {
            [File]::Move($srcMeta, $dstMeta)
        }
    }

    Compress-Archive -Path $xluaBuildDir "$projectRoot\dist\XLua-2.1.12.0.zip"
}
catch {
    Write-Output $PSItem | Format-List -Force
    Read-Host
}