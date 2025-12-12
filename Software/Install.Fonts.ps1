<#
.SYNOPSIS
    Installs all .ttf and .otf fonts from a specified folder system-wide.
.DESCRIPTION
    Copies font files to C:\Windows\Fonts and registers them in the HKLM registry hive.
    Must be run as Administrator.
.PARAMETER FontFolder
    Path to the folder containing font files (.ttf, .otf).
.EXAMPLE
    .\Install-FontsSystemWide.ps1 -FontFolder "C:\MyFonts"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if (-Not (Test-Path $_ -PathType Container)) {
            throw "Font folder does not exist: $_"
        }
        return $true
    })]
    [string]$FontFolder
)

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "❌ This script must be run as Administrator to install fonts system-wide."
    exit 1
}

# Supported font extensions
$fontExtensions = @('.ttf', '.otf')
$fontFiles = Get-ChildItem -Path $FontFolder -File | Where-Object {
    $_.Extension -in $fontExtensions
}

if ($fontFiles.Count -eq 0) {
    Write-Warning "No .ttf or .otf font files found in: $FontFolder"
    exit 0
}

Write-Host "📁 Found $($fontFiles.Count) font(s) in: $FontFolder" -ForegroundColor Cyan

# Load Shell.Application for font name extraction
$shell = New-Object -ComObject Shell.Application
$systemFontsDir = "C:\Windows\Fonts"
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

foreach ($fontFile in $fontFiles) {
    try {
        # Extract actual font name using Shell details
        $folderObj = $shell.Namespace($fontFile.DirectoryName)
        $itemObj = $folderObj.ParseName($fontFile.Name)
        $fontName = $folderObj.GetDetailsOf($itemObj, 21)  # Property 21 = Font title

        # Fallback to filename if shell fails
        if ([string]::IsNullOrWhiteSpace($fontName)) {
            $fontName = $fontFile.BaseName
        }

        # Determine registry value suffix
        $fontType = if ($fontFile.Extension -eq '.otf') { ' (OpenType)' } else { ' (TrueType)' }
        $regValueName = "$fontName$fontType"

        # Copy font file to system directory
        $destPath = Join-Path $systemFontsDir $fontFile.Name
        Copy-Item -Path $fontFile.FullName -Destination $destPath -Force

        # Register in registry
        Set-ItemProperty -Path $regPath -Name $regValueName -Value $fontFile.Name -ErrorAction Stop

        Write-Host "✅ Installed: $fontName" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install '$($fontFile.Name)': $($_.Exception.Message)"
    }
}

Write-Host "`n🎉 Font installation complete!" -ForegroundColor Magenta