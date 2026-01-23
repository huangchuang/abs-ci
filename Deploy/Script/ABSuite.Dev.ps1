param(
    [Parameter(Mandatory = $true)]
    [string]$DeployFolder
)

$current_dir = $PSScriptRoot

& $current_dir\VS2022.install.ps1 BuildTools $current_dir\VS2022.vsconfig

& $current_dir\SQL2022.install.ps1 $current_dir\SQL2022.ini

& $current_dir\ABSuite.Dev.Software.Install.ps1    -DeployFolder $DeployFolder
& $current_dir\ABSuite.Dev.Environment.Install.ps1 -DeployFolder $DeployFolder

& $current_dir\DockerImage.CleanUp.ps1 -DeployFolder $DeployFolder