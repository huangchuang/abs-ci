param(
    [Parameter(Mandatory = $true)]
    [string]$DeployFolder
)

function Remove-FolderIfPresent {
    param([string]$Path)
    if (Test-Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue }
}

& dism.exe /online /cleanup-image /StartComponentCleanup /ResetBase

Remove-FolderIfPresent -Path "${env:ProgramData}\Package Cache"
Remove-FolderIfPresent -Path "${env:TEMP}\*"
Remove-FolderIfPresent -Path "${env:WINDIR}\Installer\*"
Remove-FolderIfPresent -Path "${env:WINDIR}\Logs"
Remove-FolderIfPresent -Path "${env:WINDIR}\SoftwareDistribution\Download"
Remove-FolderIfPresent -Path "${env:WINDIR}\Temp\*"
Remove-FolderIfPresent -Path "$DeployFolder\Software\*"