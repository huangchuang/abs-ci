# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2022

WORKDIR C:\TEMP
ENV TEMP=C:\TEMP
ENV TMP=C:\TEMP
SHELL ["cmd", "/S", "/C"]

# Install Visual Studio Build Tools 2022 for AB Suite 10.0
COPY VS2022.vsconfig C:\TEMP\VS2022.vsconfig
COPY install.ps1 C:\TEMP\install.ps1
COPY parse_args.ps1 C:\TEMP\parse_args.ps1

RUN curl.exe -fSL "https://aka.ms/vs/17/release/vs_buildtools.exe" -o vs_buildtools.exe

# RUN Powershell -Command "& { `
#    # $ProgressPreference = 'SilentlyContinue'; `
#    # $InformationPreference = 'SilentlyContinue'; `
#    Unblock-File -Path C:\\Temp\\vs_buildtools.exe; `
#    $args = @('-File', 'C:\TEMP\parse_args.ps1', '--quiet', '--wait', '--norestart', '--nocache', 'install', '--config', 'C:\Temp\VS2022.vsconfig', '--installPath', '\"%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\"'); `
#    # $process = Start-Process -FilePath C:\\Temp\\vs_buildtools.exe -ArgumentList $args -PassThru; `
#    $process = Start-Process -FilePath PowerShell.exe -ArgumentList $args -PassThru; `
#    Write-Host "Visual Studio Build Tools installation started."; `
#    $process.WaitForExit(); `
#    if (($process.ExitCode -eq 0) -or ($process.ExitCode -eq 3010)) { `
#       Write-Host "Visual Studio Build Tools installation succeeded. Exit code: $($process.ExitCode)"; `
#       exit 0; `
#    } else { `
#       # Write-Error "Visual Studio Build Tools installation failed. Exit code: $($process.ExitCode)"; `
#       $latestLog = Get-ChildItem -Path ${env:TEMP} -Filter "dd_bootstrapper_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1; `
#       $logMsg = Get-Content -Path $latestLog; `
#       Write-Host $logMsg; `
#       exit $process.ExitCode; `
#    } `
# }"

RUN PowerShell -File C:\Temp\install.ps1

# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
CMD ["Powershell"]