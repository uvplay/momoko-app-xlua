using namespace System.IO

$projectRoot = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$tempDir = "$projectRoot\temp"
[Directory]::CreateDirectory($tempDir) | Out-Null

# https://visualstudio.microsoft.com/downloads/
$uri = "https://download.visualstudio.microsoft.com/download/pr/c6e2b90d-9051-44bd-aef1-4ef3bdf8f084/30b5724c490239eee9608d63225b994f/vs_buildtools.exe"
Invoke-WebRequest -Uri $uri -OutFile "$tempDir\vs_buildtools.exe"

# https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio#list-of-workload-ids-and-component-ids
# https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
& "$tempDir\vs_buildtools.exe" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive