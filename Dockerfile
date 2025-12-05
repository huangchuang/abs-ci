# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2025

WORKDIR C:\TEMP
ENV TEMP=C:\TEMP
ENV TMP=C:\TEMP

COPY Software/ C:\Software\
COPY SQL2022/  C:\TEMP\SQL2022\

RUN PowerShell -File C:\Software\VS2022.install.ps1 BuildTools C:\Software\VS2022.vsconfig

RUN C:\TEMP\SQL2022\setup.exe /ConfigurationFile=C:\Software\SQL2022.ini /IAcceptSQLServerLicenseTerms

RUN PowerShell -File C:\Software\ABSuite.Build.Software.Install.ps1

RUN PowerShell -File C:\Software\CleanUp.ps1

CMD ["cmd.exe", "/K", "%ProgramFiles%\\Microsoft Visual Studio\\2022\\Professional\\Common7\\Tools\\VsDevCmd.bat"]