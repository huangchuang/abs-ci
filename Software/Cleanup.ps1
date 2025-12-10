function Remove-FolderIfPresent {
    param([string]$Path)
    if (Test-Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue }
}

& dism.exe /online /cleanup-image /StartComponentCleanup /ResetBase

Remove-FolderIfPresent -Path "${env:ProgramData}\Package Cache"
Remove-FolderIfPresent -Path "${env:TEMP}\*"
Remove-FolderIfPresent -Path "${env:WINDIR}\Installer"
Remove-FolderIfPresent -Path "${env:WINDIR}\Logs"
Remove-FolderIfPresent -Path "${env:WINDIR}\SoftwareDistribution\Download"
Remove-FolderIfPresent -Path "${env:WINDIR}\Temp\*"
Remove-FolderIfPresent -Path "C:\Software\Client Environment"
Remove-FolderIfPresent -Path "C:\Software\Grep"
Remove-FolderIfPresent -Path "C:\Software\Heatwave"
Remove-FolderIfPresent -Path "C:\Software\MSOLEDB 19"
Remove-FolderIfPresent -Path "C:\Software\OpenJDK"
Remove-FolderIfPresent -Path "C:\Software\ScriptEncoder"
Remove-FolderIfPresent -Path "C:\Software\UnisysOLEDB"
Remove-FolderIfPresent -Path "C:\Software\UnitTestFramework"