param(
    [Parameter(Mandatory = $true)]
    [string]$DeployFolder
)

$global:DeployFolder = $DeployFolder

function Install-Fonts {
    Write-Host "Install Fonts started."
    & "${global:DeployFolder}\Software\ABSuite.Test.Install.Fonts.ps1" -font_dir "${global:DeployFolder}\Software\Fonts"
    Write-Host "Install Fonts succeeded, exit: $exit"
}

function Install-MicrosoftXPSDocumentWriter-Printer {
    # TODO: Failed to find a valid way to install XPS Document Writer silently inside container
    Write-Host "Failed to find a valid way to install XPS Document Writer silently inside container"
}

# Use WMI/PrintUI instead of PrintManagement (not present in Server Core).
function Install-MicrosoftXPSDocumentWriter-Printer-2 {
    $printerName = "Microsoft XPS Document Writer"
    $portName = "PORTPROMPT:"
    $driverName = "Microsoft XPS Document Writer"

    Write-Host "Enabling XPS feature..."
    dism /online /enable-feature /featurename:Printing-XPSServices-Features /all /quiet /norestart | Out-Null

    Write-Host "Starting Print Spooler..."
    Start-Service -Name Spooler -ErrorAction SilentlyContinue

    $existing = Get-CimInstance -ClassName Win32_Printer -Filter ("Name='{0}'" -f $printerName.Replace("'", "''")) -ErrorAction SilentlyContinue
    if (-not $existing) {
        # Install printer using PrintUI (works on Server Core)
        $cmd = "printui.dll,PrintUIEntry /if /b ""$printerName"" /r ""$portName"" /m ""$driverName"""
        Write-Host "Adding printer: $printerName"
        rundll32.exe $cmd | Out-Null
    }

    Write-Host "Setting default printer: $printerName"
    $wmiPrinter = Get-CimInstance -ClassName Win32_Printer -Filter ("Name='{0}'" -f $printerName.Replace("'", "''"))
    if ($wmiPrinter) { $null = $wmiPrinter.SetDefaultPrinter() }
    else { Write-Error "Printer '$printerName' not found." }
}

# DISM error 12002 means it tried to reach Windows Update and timed out (common in containers). Use a local source and -LimitAccess.
#
# Below is a drop‑in update for the function to accept a local SxS source (from the matching Windows ServerCore ISO or extracted base image). Set $sourcePath to a valid \sources\sxs folder.
function Install-MicrosoftXPSDocumentWriter-Printer-3 {
    $printerName = "Microsoft XPS Document Writer"
    $portName = "PORTPROMPT:"
    $driverName = "Microsoft XPS Document Writer"

    # TODO: set this to a valid SxS path that matches the container OS build
    $sourcePath = "C:\sources\sxs"

    Write-Host "Enabling XPS feature..."
    if (Test-Path $sourcePath) {
        dism /online /enable-feature /featurename:Printing-XPSServices-Features /all /quiet /norestart /LimitAccess /Source:$sourcePath | Out-Null
    } else {
        Write-Error "SxS source not found at $sourcePath. Provide a valid source to install XPS feature."
        return
    }

    Write-Host "Starting Print Spooler..."
    Start-Service -Name Spooler -ErrorAction SilentlyContinue

    $existing = Get-CimInstance -ClassName Win32_Printer -Filter ("Name='{0}'" -f $printerName.Replace("'", "''")) -ErrorAction SilentlyContinue
    if (-not $existing) {
        $cmd = "printui.dll,PrintUIEntry /if /b ""$printerName"" /r ""$portName"" /m ""$driverName"""
        Write-Host "Adding printer: $printerName"
        rundll32.exe $cmd | Out-Null
    }

    Write-Host "Setting default printer: $printerName"
    $wmiPrinter = Get-CimInstance -ClassName Win32_Printer -Filter ("Name='{0}'" -f $printerName.Replace("'", "''"))
    if ($wmiPrinter) { $null = $wmiPrinter.SetDefaultPrinter() }
    else { Write-Error "Printer '$printerName' not found." }
}

function List-Certificates {
    # Lists certificates under Current User > Personal (My) store
    Get-ChildItem -Path Cert:\CurrentUser\My |
    Select-Object Subject, Issuer, Thumbprint, NotBefore, NotAfter |
    Where-Object {$_.Issuer -like "*localhost*"} |
    Sort-Object Subject

    # Lists certificates under Local Computer > Trusted Root Certification Authorities (Root)
    Get-ChildItem -Path Cert:\LocalMachine\Root |
    Select-Object Subject, Issuer, Thumbprint, NotBefore, NotAfter |
    Where-Object {$_.Issuer -like "*localhost*"} |
    Sort-Object Subject
}

function Install-NET-Certificates {
    Write-Host "Certificates before the installation:"
    List-Certificates

    Write-Host "Installing localhost certificate..."
    $cert = New-SelfSignedCertificate `
    -DnsName "localhost" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(10)

    # Copies the localhost certificate from CurrentUser\My to CurrentUser\Root
    $sourceStore = "Cert:\CurrentUser\My"
    $targetStore = "Cert:\CurrentUser\Root"

    $cert = Get-ChildItem $sourceStore |
        Where-Object { $_.Subject -match "CN=localhost" } |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1

    if (-not $cert) { throw "localhost certificate not found in $sourceStore" }

    $tmpCer = Join-Path $env:TEMP "localhost.cer"
    Export-Certificate -Cert $cert -FilePath $tmpCer | Out-Null
    certutil -addstore -f Root $tmpCer

    Write-Host "Certificates after the installation:"
    List-Certificates
}

function Install-MCP-Certificates {
    # TODO: Implement MCP certificate installation if needed
}

Install-Fonts
Install-MicrosoftXPSDocumentWriter-Printer
Install-NET-Certificates
Install-MCP-Certificates