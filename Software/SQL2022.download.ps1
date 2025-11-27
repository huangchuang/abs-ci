# Write-Output "1. Download SQL Server 2022 installation media started."
# Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2215158" -OutFile "${env:TEMP}\\SQL2022-SSEI-Dev.exe"
# Write-Output "2. Download SQL Server 2022 installation offline files."
# $SQL2022_Download_Folder = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "SQL2022"
# $process = Start-Process -FilePath "${env:TEMP}\\SQL2022-SSEI-Dev.exe" -ArgumentList @('/ACTION=Download', "/MEDIAPATH=$SQL2022_Download_Folder", 'MEDIATYPE=ISO', '/QUIET') -PassThru -Wait -NoNewWindow;
# $process.WaitForExit();