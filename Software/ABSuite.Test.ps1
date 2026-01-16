$current_dir = $PSScriptRoot

& $current_dir\ABSuite.Test.Software.Install.ps1
& $current_dir\ABSuite.Test.Environment.Install.ps1

& $current_dir\DockerImage.CleanUp.ps1