param(
    [string]$config
)

Write-Output "1. Downloading the SQL Server 2022 installer..."
$installation_media = "${env:TEMP}\SQL2022-SSEI-Dev.exe"
Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2215158" -OutFile "$installation_media"

Write-Output "2. Downloading the SQL Server 2022 offline CAB files ..."
$installation_download_folder = "${env:TEMP}\SQL2022_Download"
$process = Start-Process -FilePath "$installation_media" -ArgumentList @('/ACTION=Download', "/MEDIAPATH=$installation_download_folder", 'MEDIATYPE=CAB', '/QUIET') -PassThru -Wait -NoNewWindow;
$process.WaitForExit()

Write-Output "3. Extracting the SQL Server 2022 offline CAB files ..."
Push-Location "$installation_download_folder"
$process = Start-Process -FilePath .\SQLServer2022-DEV-x64-ENU.exe -ArgumentList @('/q','x') -PassThru -Wait -NoNewWindow
$process.WaitForExit()
Pop-Location

Write-Output "4. Installing the SQL Server 2022 ..."
Push-Location "$installation_download_folder"
$arguments = @("/ConfigurationFile=${config}", '/IAcceptSQLServerLicenseTerms', '/Q')
$process = Start-Process -FilePath .\SQLServer2022-DEV-x64-ENU\setup.exe -ArgumentList $arguments -PassThru -Wait -NoNewWindow
$process.WaitForExit()
Pop-Location
Write-Output "5. SQL Server 2022 installation completed with exit code: $($process.ExitCode)"