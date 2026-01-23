param(
    [Parameter(Mandatory = $true)]
    [string]$DeployFolder
)

$current_dir = $PSScriptRoot

& $current_dir\ABSuite.Test.Software.Install.ps1    -DeployFolder $DeployFolder
& $current_dir\ABSuite.Test.Environment.Install.ps1 -DeployFolder $DeployFolder

& $current_dir\DockerImage.CleanUp.ps1 -DeployFolder $DeployFolder