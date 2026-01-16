# Required by ModelTest
function Install-NGENPrototypedApp {
    Write-Host "Install NGENPrototypedApp started."
    $msi = "C:\Software\NGENPrototypedApp.msi"
    # Base arguments for a truly silent install with full logging and no reboot
    $arguments = @('/q', 'REBOOT=ReallySuppress', 'MSIRESTARTMANAGERCONTROL=Disable', '/i', "$msi", 'userCode=AppUser', 'domain=.', 'password=Absuite@12345678', 'dropBS=TRUE', 'enableAfterDeploy=TRUE', '/lv', 'C:\Software\1.log')

    $process = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $arguments -PassThru -Wait -NoNewWindow
    $exit = if ($process) { $process.ExitCode } else { $LASTEXITCODE }

    Write-Host "Install NGENPrototypedApp succeeded, exit: $exit"
    $log = Get-Content 'C:\Software\1.log'
    Write-Host $log
}

Install-NGENPrototypedApp