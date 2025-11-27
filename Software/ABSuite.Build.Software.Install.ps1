# $now = Get-Date -Format "yyyyMMdd HHmmss"; Write-Output "3 $now";
# docker run -it -d --name test-vs22-sql22 --mount=type=bind,source=D:\ABSuite\abs-ci\trunk,target=C:\ABSuite\ABSF\trunk --entrypoint "cmd.exe" ltsc2025:vs22.sql22 cmd /K "echo Hello AB Suite"

function Install-SSMS {
    Write-Output "Install SSMS started."
    $process = Start-Process -FilePath "C:\Software\SSMS-Setup-ENU.exe" -ArgumentList @('/i', '/passive', '/norestart') -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install SSMS succeeded."
}

function Install-Grep {
    Write-Output "Install Grep started."
    $process = Start-Process -FilePath "C:\Software\grep-2.5.4-setup.exe" -ArgumentList @('/Silent') -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install Grep succeeded."
}

function EnableMSMQ {
    $features = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like 'MSMQ*' }

    foreach ($f in $features) { Write-Host "Found feature: $($f.FeatureName) - State: $($f.State)" }

    foreach ($f in $features) {
        switch ($f.State) {
            'Enabled' {
                Write-Host "Already enabled: $($f.FeatureName)" -ForegroundColor Green
            }
            'Disabled' {
                Write-Host "Enabling: $($f.FeatureName) ..." -ForegroundColor Yellow
                try {
                    $result = Enable-WindowsOptionalFeature -Online -FeatureName $f.FeatureName -All -NoRestart -ErrorAction Stop
                    if ($result.RestartNeeded) { $rebootNeeded = $true }
                    Write-Host "Enabled: $($f.FeatureName)" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to enable $($f.FeatureName): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            default {
                Write-Host "Skipping $($f.FeatureName) (state: $($f.State))" -ForegroundColor DarkGray
            }
        }
    }

    foreach ($f in $features) { Write-Host "Found feature: $($f.FeatureName) - State: $($f.State)" }
}

function Install-HeatWave{}

function Install-OpenJDK {}

function Install-ScriptEncoder {
    Write-Output "Install Script Encoder started."
    $process = Start-Process -FilePath "C:\Software\sce10en.exe" -ArgumentList @('/q') -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install Script Encoder succeeded."
}

function Install-ComponentEnabler {
    Write-Output "Install Component Enabler started."
    $ce_installer = "Client Environment\\Component Enabler\\Agile Business Suite 10.0 Component Enabler.msi"
    $jdk_bin = "${env:JAVA_HOME}\\bin"
    @args=@("/i", """$ce_installer""", "/qn", "/norestart", "ADDLOCAL=ALL", "JAVA_HOME=${jdk_bin}", "/l*", "component_enabler.log", "INSTALLDIR=C:\\NGEN_CE")
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $args -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install Component Enabler succeeded."
}

function Install-MSOLEDBDriver19 {
    Write-Output "Install MSOLEDBSql started."
    $args=@('/i', 'C:\Software\msoledbsql.msi', 'ADDLOCAL=ALL', '/passive', 'IACCEPTMSOLEDBSQLLICENSETERMS=YES', '/norestart');
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $args -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install MSOLEDBSql succeeded."
}
