param(
    [Parameter(Mandatory = $true)]
    [string]$DeployFolder
)

$global:DeployFolder = $DeployFolder

function Invoke-WebRequestWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$Uri,        
        [Parameter(Mandatory = $true)] [string]$OutFile,        
        [Parameter(Mandatory = $false)] [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    $success = $false
    
    while ($retryCount -lt $MaxRetries) {
        try {
            Write-Host "Attempt $($retryCount + 1) of $MaxRetries to download from: $Uri"
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile
            $success = $true
            Write-Host "Download completed successfully."
            break
        }
        catch {
            $retryCount++
            Write-Warning "Attempt $($retryCount) failed: $($_.Exception.Message)"
            if ($retryCount -lt $MaxRetries) {
                Write-Host "Retrying in 3 seconds..."
                Start-Sleep -Seconds 3
            }
        }
    }
    
    if (-not $success) {
        throw "Failed to download from '$Uri' after $MaxRetries attempts. Last error: $($_.Exception.Message)"
    }
}

function Install-ComponentEnabler {
    Write-Output "Install Component Enabler - started."
    $ce_installer = "${global:DeployFolder}\Software\Client Environment\Component Enabler\Agile Business Suite 10.0 Component Enabler.msi"
    $jdk_bin = "${env:JAVA_HOME}\\bin"
    $arguments=@("/i", """$ce_installer""", "/qn", "/norestart", "ADDLOCAL=ALL", "JAVA_HOME=${jdk_bin}", "/l*", "component_enabler.log", "INSTALLDIR=C:\\NGEN_CE")
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $arguments -PassThru -Wait -NoNewWindow
    $process.WaitForExit()
    Write-Output "Install Component Enabler - succeeded."
}

function Install-Grep {
    Write-Output "Install Grep - started."
    $process = Start-Process -FilePath "${global:DeployFolder}\Software\Grep\grep-2.5.4-setup.exe" -ArgumentList @('/Silent') -PassThru -Wait -NoNewWindow
    $process.WaitForExit()
    Write-Output "Install Grep - succeeded."
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

function Install-MSOLEDBDriver19 {
    Write-Output "Install MSOLEDBSql - started."
    $arguments=@('/i', """${global:DeployFolder}\Software\MSOLEDB 19\msoledbsql.msi""", 'ADDLOCAL=ALL', '/quiet', 'IACCEPTMSOLEDBSQLLICENSETERMS=YES', '/norestart')
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $arguments -PassThru -Wait -NoNewWindow
    $process = Get-Process -Name msiexec -ErrorAction SilentlyContinue
    if ($process) { $process.WaitForExit() }
    Write-Output "Install MSOLEDBSql - succeeded."
}

function Install-NodeJS {
    Write-Output "Install Node.js - started."
    $version="24.12.0"
    $url = ('https://nodejs.org/dist/v{0}/node-v{0}-win-x64.zip' -f $version)
    $zip = "${global:DeployFolder}\Software\node.zip"
    Write-Output "Downloading Node.js from $url"
    Invoke-WebRequestWithRetry -Uri $url -OutFile $zip -MaxRetries 3
    Write-Output "Extracting Node.js to C:\Program Files (x86)"
    Expand-Archive -Path $zip -DestinationPath 'C:\Program Files (x86)' -Force
    Remove-Item -Path $zip -Force
    Write-Output "Install Node.js - succeeded."
}

function Install-NuGetConfig {
    $destination = "${env:AppData}\NuGet"
    if (-not (Test-Path -Path "${destination}")) {
        New-Item -ItemType Directory -Path "${destination}"
    }
    Copy-Item -Force -Path "${global:DeployFolder}\Software\NuGet.Config" -Destination "${destination}\nuget.config"
}

function Install-OpenJDK {
    Write-Output "Install OpenJDK - started."
    $zip = "openjdk-25.0.1_windows-x64_bin.zip"
    $url = "https://download.java.net/java/GA/jdk25.0.1/2fbf10d8c78e40bd87641c434705079d/8/GPL/$zip"
    $zip = "${global:DeployFolder}\Software\$zip"
    Invoke-WebRequestWithRetry -Uri $url -OutFile "$zip" -MaxRetries 3
    Expand-Archive -Path "$zip" -DestinationPath "$env:TEMP" -Force
    Move-Item -Force -Path "$env:TEMP\jdk-25.0.1" -Destination "C:\OpenJDK"
    Remove-Item -Path $zip -Force
    Write-Output "Install OpenJDK - succeeded."
}

function Install-ScriptEncoder {
    Write-Output "Install ScriptEncoder - started."
    $process = Start-Process -FilePath "${global:DeployFolder}\Software\ScriptEncoder\sce10en.exe" -ArgumentList @('/q') -PassThru -Wait -NoNewWindow
    $process.WaitForExit()
    Write-Output "Install ScriptEncoder - succeeded."
}

function Install-TortoiseSVN {
    Write-Output "Install TortoiseSVN - started."
    $msi = "${global:DeployFolder}\Software\TortoiseSVN\TortoiseSVN-1.14.9.29743-x64-svn-1.14.5.msi"
    $arguments=@("/i", "$msi", "ADDLOCAL=ALL", "/passive", "/norestart", "/log", "TortoiseSVN_Install.log")
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $arguments -PassThru -Wait -NoNewWindow
    $process = Get-Process -Name msiexec -ErrorAction SilentlyContinue
    if ($process) { $process.WaitForExit() }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "TortoiseSVN installed successfully."
    } else {
        Write-Host "TortoiseSVN installer exited with code $LASTEXITCODE - ${$process.exitcode}"
    }

    Write-Output "Install TortoiseSVN - succeeded."
}

function Install-UnisysOLEDBDriver {
    Write-Output "Install Unisys OLEDB - started."
    $arguments=@('/i', """${global:DeployFolder}\Software\UnisysOLEDB\OLEDBx64.msi""", 'ADDLOCAL=ALL', '/quiet', 'IACCEPTMSOLEDBSQLLICENSETERMS=YES', '/norestart')
    $process = Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList $arguments -PassThru -Wait -NoNewWindow
    $process = Get-Process -Name msiexec -ErrorAction SilentlyContinue
    if ($process) { $process.WaitForExit() }
    Write-Output "Install Unisys MSOLEDB - succeeded."
}

function Install-UnitTestFrameworkDll {
    Write-Output "Install UnitTestFramework.dll - started."
    $destination = "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\PublicAssemblies"
    if (Test-Path -Path "${destination}") {
        Copy-Item -Recurse -Force -Path "${global:DeployFolder}\Software\UnitTestFramework\Microsoft.VisualStudio.QualityTools.UnitTestFramework.dll" -Destination "${destination}"
    }
    Write-Output "Install UnitTestFramework.dll - succeeded."
}

# function Install-SSMS {
#     Write-Output "Install SSMS started."
#     $process = Start-Process -FilePath "${global:DeployFolder}\Software\SSMS-Setup-ENU.exe" -ArgumentList @('/i', '/passive', '/norestart') -PassThru -Wait -NoNewWindow
#     $process.WaitForExit()
#     Write-Output "Install SSMS succeeded."
# }

# function Install-Winzip {
#     Write-Output "Install Winzip started."
#     $process = Start-Process -FilePath "${global:DeployFolder}\Software\WinZip\WinZip_28WinZip_28.0.15620_u1.18.exe" -ArgumentList @('/Silent') -PassThru -Wait -NoNewWindow
#     $process.WaitForExit()
#     Write-Output "Install Winzip succeeded."
# }

Install-ComponentEnabler
Install-Grep
Install-MSMQ
Install-MSOLEDBDriver19
Install-NodeJS
Install-NuGetConfig
Install-OpenJDK
Install-ScriptEncoder
Install-TortoiseSVN
Install-UnisysOLEDBDriver
Install-UnitTestFrameworkDll