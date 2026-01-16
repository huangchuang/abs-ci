& $current_dir\ABSuite.Test.Install.Fonts.ps1
function Install-Fonts {
    Write-Host "Install Fonts started."
    & "C:\Software\ABSuite.Test.Install.Fonts.ps1" -font_dir "C:\Software\Fonts"
    Write-Host "Install Fonts succeeded, exit: $exit"
}

Install-Fonts