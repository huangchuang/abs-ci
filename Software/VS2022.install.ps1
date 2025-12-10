param(
    [string]$edition,
    [string]$config
)

$installPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\$edition"
$bootstrapperUrl = "https://aka.ms/vs/17/release/vs_${edition}.exe"
$bootstrapperExe = "${env:TEMP}\vs_${edition}.exe"

Write-Host "Downloading Visual Studio 2022 ${edition} bootstrapper..." -ForegroundColor Cyan
try { Invoke-WebRequest -Uri $bootstrapperUrl -OutFile $bootstrapperExe -UseBasicParsing  -ErrorAction Stop;}
catch { Write-Error "Failed to download bootstrapper: $_"; exit 1; }

Write-Host "Installing Visual Studio 2022 ${edition} using config file: ${config} in quiet mode..." -ForegroundColor Green
$arguments = @("--installPath", """$installPath""", "--config", """$config""", "--quiet", "--wait", "--norestart")
$process = Start-Process -FilePath $bootstrapperExe -ArgumentList $arguments -Wait -NoNewWindow -PassThru
$process.WaitForExit()

switch ($process.ExitCode) {
    0 { Write-Host "Installation completed successfully." -ForegroundColor Green; exit 0; }
    default {  Write-Error "Installation failed with exit code: $($process.ExitCode)"; exit $process.ExitCode; }
}