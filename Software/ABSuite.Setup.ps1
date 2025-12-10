$current_dir = $PSScriptRoot

& $current_dir\VS2022.install.ps1 BuildTools $current_dir\VS2022.vsconfig

& $current_dir\SQL2022.install.ps1 $current_dir\SQL2022.ini

& $current_dir\ABSuite.Build.Software.Install.ps1
& $current_dir\ABSuite.Build.Environment.Install.ps1

& $current_dir\CleanUp.ps1