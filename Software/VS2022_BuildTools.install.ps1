param(
    [string]$config
)

$vs_buildtools_installer = "${env:TEMP}\vs_buildtools.exe";
$vs_buildtools_installPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools"
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_buildtools.exe" -OutFile $vs_buildtools_installer -UseBasicParsing -ErrorAction Stop
Unblock-File -Path $vs_buildtools_installer;

$args = @('--quiet', '--wait', '--norestart', '--nocache', 'install', '--config', $config, '--installPath', """$vs_buildtools_installPath""");
Write-Output "Visual Studio Build Tools installation started.";
$process = Start-Process -FilePath $vs_buildtools_installer -ArgumentList $args -PassThru -Wait -NoNewWindow;
$process.WaitForExit();
if (0 -eq $process.ExitCode) {
    Write-Output "Visual Studio Build Tools installation succeeded with exit code $($process.ExitCode).";
    Remove-Item -Recurse -Force "${env:TEMP}\\*.log"
} else {
    Get-ChildItem -Path "${env:TEMP}\\dd_bootstrapper_*.log" | ForEach-Object {
        Write-Host "--- Log file: $($_.FullName) ---";
        Get-Content -Path $_.FullName;
        Write-Host "--- End of log file ---" };
    Write-Error "Visual Studio Build Tools installation failed with exit code $($process.ExitCode).";
}
exit $process.ExitCode;