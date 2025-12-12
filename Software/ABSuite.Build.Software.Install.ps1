# $now = Get-Date -Format "yyyyMMdd HHmmss"; Write-Output "3 $now";
# docker run -it -d --name test-vs22-sql22 --mount=type=bind,source=D:\ABSuite\abs-ci\trunk,target=C:\ABSuite\ABSF\trunk ltsc2025:vs22.sql22 cmd /K "echo Hello AB Suite"

function Install-SSMS {
    Write-Output "Install SSMS started."
    $process = Start-Process -FilePath "C:\Software\SSMS-Setup-ENU.exe" -ArgumentList @('/i', '/passive', '/norestart') -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install SSMS succeeded."
}

function Install-Grep {
    Write-Output "Install Grep started."
    $process = Start-Process -FilePath "C:\Software\Grep\grep-2.5.4-setup.exe" -ArgumentList @('/Silent') -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install Grep succeeded."
}

function Install-MSMQ {
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

function Install-OpenJDK {
    Copy-Item -Recurse -Force -Path "C:\Software\OpenJDK" -Destination "C:\OpenJDK" -ErrorAction Stop
}

function Install-Winzip {
    Write-Output "Install Winzip started."
    $process = Start-Process -FilePath "C:\Software\WinZip\WinZip_28WinZip_28.0.15620_u1.18.exe" -ArgumentList @('/Silent') -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install Winzip succeeded."
}

function Install-ComponentEnabler {
    Write-Output "Install Component Enabler started."
    $ce_installer = "C:\Software\Client Environment\\Component Enabler\\Agile Business Suite 10.0 Component Enabler.msi"
    $jdk_bin = "${env:JAVA_HOME}\\bin"
    $args=@("/i", """$ce_installer""", "/qn", "/norestart", "ADDLOCAL=ALL", "JAVA_HOME=${jdk_bin}", "/l*", "component_enabler.log", "INSTALLDIR=C:\\NGEN_CE")
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $args -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install Component Enabler succeeded."
}

function Install-HeatWave {}

function Install-ScriptEncoder {
    Write-Output "Install Script Encoder started."
    $process = Start-Process -FilePath "C:\Software\ScriptEncoder\sce10en.exe" -ArgumentList @('/q') -PassThru -Wait -NoNewWindow;
    $process.WaitForExit();
    Write-Output "Install Script Encoder succeeded."
}

function Install-UnisysOLEDBDriver {
    Write-Output "Install Unisys OLEDB started."
    $args=@('/i', """C:\Software\UnisysOLEDB\OLEDBx64.msi""", 'ADDLOCAL=ALL', '/quiet', 'IACCEPTMSOLEDBSQLLICENSETERMS=YES', '/norestart');
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $args -PassThru -Wait -NoNewWindow;
    $process = Get-Process -Name msiexec;
    if ($process) { $process.WaitForExit(); };
    Write-Output "Install Unisys MSOLEDB succeeded."
}

function Install-MSOLEDBDriver19 {
    Write-Output "Install MSOLEDBSql started."
    $args=@('/i', """C:\Software\MSOLEDB 19\msoledbsql.msi""", 'ADDLOCAL=ALL', '/quiet', 'IACCEPTMSOLEDBSQLLICENSETERMS=YES', '/norestart');
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $args -PassThru -Wait -NoNewWindow;
    $process = Get-Process -Name msiexec;
    if ($process) { $process.WaitForExit(); };
    Write-Output "Install MSOLEDBSql succeeded."
}

function Install-NodeJS {
    Write-Output "Install Node.js started."
    $version="24.12.0"
    $url = ('https://nodejs.org/dist/v{0}/node-v{0}-win-x64.zip' -f $version)
    Write-Output "Downloading Node.js from $url"
    Invoke-WebRequest -Uri $url -OutFile 'node.zip'
    Write-Output "Extracting Node.js to C:\Program Files (x86)"
    Expand-Archive -Path 'node.zip' -DestinationPath 'C:\Program Files (x86)' -Force
    Remove-Item -Path 'node.zip' -Force
    Write-Output "Install Node.js succeeded."
}

function Install-NuGetConfig {
    $destination = "${env:AppData}\NuGet"
    if (-not (Test-Path -Path "${destination}")) {
        New-Item -ItemType Directory -Path "${destination}"
    }
    Copy-Item -Force -Path "C:\Software\NuGet.Config" -Destination "${destination}\nuget.config"
}

function Copy-UnitTestFrameworkDll {
    $destination = "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\PublicAssemblies"
    if (Test-Path -Path "${destination}") {
        Copy-Item -Recurse -Force -Path "C:\Software\UnitTestFramework\Microsoft.VisualStudio.QualityTools.UnitTestFramework.dll" -Destination "${destination}"
    }
}

Install-Grep
Install-MSMQ
Install-OpenJDK
Install-ComponentEnabler
Install-ScriptEncoder
Install-UnisysOLEDBDriver
Install-MSOLEDBDriver19
Install-NodeJS
Install-NuGetConfig
Copy-UnitTestFrameworkDll