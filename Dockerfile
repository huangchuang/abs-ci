# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2022

WORKDIR C:\TEMP
ENV TEMP=C:\TEMP
ENV TMP=C:\TEMP
SHELL ["cmd", "/S", "/C"]

# Install Visual Studio Build Tools 2022 for AB Suite 10.0
COPY VS2022.vsconfig C:\TEMP\VS2022.vsconfig
COPY VS2022.install.ps1 C:\TEMP\VS2022.install.ps1

RUN curl.exe -fSL "https://aka.ms/vs/17/release/vs_buildtools.exe" -o vs_buildtools.exe

# RUN Powershell -Command { `
#     # $ProgressPreference = 'SilentlyContinue'; `
#     # $InformationPreference = 'SilentlyContinue'; `
#     Unblock-File -Path C:\\TEMP\\vs_BuildTools.exe; `
#     $args = @('--quiet','--wait','--norestart','--nocache','install','--config','C:\\TEMP\\VS2022.vsconfig','--installPath', '"%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools"'); `
#     $process = Start-Process -FilePath C:\\TEMP\\vs_buildtools.exe  -ArgumentList $args -PassThru -Wait -NoNewWindow; `
#     Write-Host "Visual Studio Build Tools installation started."; `
#     $process.WaitForExit(); `
#     Write-Output $process.ExitCode; `
#     if (($process.ExitCode -eq 0) -or ($process.ExitCode -eq 3010)) { `
#         Write-Host "Visual Studio Build Tools installed successfully."; `
#         exit 0; `
#     } else { `
#         Write-Error "Visual Studio Build Tools installation failed with exit code $($process.ExitCode)"; `
#         Get-ChildItem -Path "${env:TEMP}\\dd_bootstrapper_*.log" | ForEach-Object { Write-Host "--- Log file: $($_.FullName) ---"; Get-Content -Path $_.FullName; Write-Host "--- End of log file ---" }; `
#         Copy-Item -Path "${env:TEMP}\\dd_*.log" -Destination "C:\\logs\\"; `
#         exit $process.ExitCode; `
#     } `
# }

RUN PowerShell -File C:\TEMP\VS2022.install.ps1

# Set an env var for easier reuse (adjust if your path differs)
ENV VS_DEV_CMD="C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat"

# ENTRYPOINT starts PowerShell, loads VS dev environment, stays interactive
# -NoExit keeps the session open
# Using & to invoke the batch file; its env changes persist in this PowerShell process.
ENTRYPOINT ["powershell.exe", `
            "-NoLogo", `
            "-ExecutionPolicy", "Bypass", `
            "-NoExit", `
            "-Command", `
            "& \"$Env:VS_DEV_CMD\" -no_logo; Write-Host 'VS Dev environment initialized.'"]

CMD ["Powershell"]