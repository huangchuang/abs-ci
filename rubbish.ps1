Unblock-File -Path C:\\temp\\vs_BuildTools.exe;
$args = @('--passive', '--wait', '--norestart', '--nocache', 'install', '--config', 'C:\Temp\VS2022.vsconfig', '--installPath', '\"%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\"');
$process = Start-Process -FilePath C:\Temp\vs_buildtools.exe -ArgumentList $args -Wait -NoNewWindow -PassThru;
Write-Host "Visual Studio Build Tools installation started.";
$process.WaitForExit();
if (($process.ExitCode -eq 0) -or ($process.ExitCode -eq 3010)) {
    Write-Host "Visual Studio Build Tools installation succeeded. Exit code: $($process.ExitCode)";
    exit 0;
} else {
    # Write-Error "Visual Studio Build Tools installation failed. Exit code: $($process.ExitCode)";
    $latestLog = Get-ChildItem -Path ${env:TEMP} -Filter "dd_bootstrapper_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1;
    $logMsg = Get-Content -Path $latestLog;
    Write-Host $logMsg;
    exit $process.ExitCode;
}