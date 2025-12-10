# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2025

WORKDIR C:\TEMP
ENV TEMP=C:\TEMP
ENV TMP=C:\TEMP
ENV JAVA_HOME=C:\OpenJDK
RUN SETX /M PATH "%PATH%;C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\IDE;C:\ABSuite\ABSF\trunk\Debug\bin64;C:\Program Files\WinZip;C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64;C:\OpenJDK\bin"

COPY Software/ C:\Software\

RUN PowerShell -File C:\Software\ABSuite.Setup.ps1

CMD cmd.exe "/K" "%ProgramFiles%\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat"