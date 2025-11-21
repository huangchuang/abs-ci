Unblock-File -Path C:\\temp\\vs_BuildTools.exe;
$args = @('--quiet','--wait','--norestart','--nocache','install','--config','C:\\Temp\\VS2022.vsconfig','--installPath', '"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"');
$process = Start-Process -FilePath C:\\temp\\vs_buildtools.exe  -ArgumentList $args -PassThru -Wait -NoNewWindow;
Write-Host "Visual Studio Build Tools installation started.";
$process.WaitForExit();
Write-Output $process.ExitCode;
if (($process.ExitCode -eq 0) -or ($process.ExitCode -eq 3010)) {
    Write-Host "Visual Studio Build Tools installed successfully.";
    exit 0;
} else {
    Write-Error "Visual Studio Build Tools installation failed with exit code $($process.ExitCode)";
    Get-ChildItem -Path "${env:TEMP}\\dd_*.log" | ForEach-Object { Write-Host "--- Log file: $($_.FullName) ---"; Get-Content -Path $_.FullName; Write-Host "--- End of log file ---" };
    Copy-Item -Path "${env:TEMP}\\dd_*.log" -Destination "C:\\logs\\";
    exit $process.ExitCode;
}