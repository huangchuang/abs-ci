param(
    [string]$vs_buildtools_installer,
    [string]$vs_buildtools_config,
    [string]$vs_buildtools_installPath
)

Unblock-File -Path $vs_buildtools_installer;
$args = @('--quiet', '--wait', '--norestart', '--nocache', 'install', '--config', $vs_buildtools_config, '--installPath', """$vs_buildtools_installPath""");
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