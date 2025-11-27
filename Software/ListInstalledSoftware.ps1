function Get-UninstallRegistryItems {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$RegistryPaths
    )
    $items = foreach ($path in $RegistryPaths) {
        try {
            Get-ChildItem -Path $path -ErrorAction Stop |
            ForEach-Object {
                try {
                    $props = Get-ItemProperty -Path $_.PSPath -ErrorAction Stop
                    # Filter entries without a display name
                    if (-not $props.DisplayName) { return }
                    [PSCustomObject]@{
                        Name            = $props.DisplayName
                        Version         = $props.DisplayVersion
                        Publisher       = $props.Publisher
                        InstallDate     = if ($props.InstallDate) {
                            # Many entries store yyyymmdd
                            $s = $props.InstallDate.ToString()
                            if ($s.Length -eq 8) {
                                [datetime]::ParseExact($s, 'yyyyMMdd', $null)
                            } else { $props.InstallDate }
                        } else { $null }
                        UninstallString = $props.UninstallString
                        InstallLocation = $props.InstallLocation
                        SystemComponent = $props.SystemComponent
                        ReleaseType     = $props.ReleaseType
                        Language        = $props.Language
                        Source          = $path
                        Architecture    = if ($path -like '*Wow6432Node*') { 'x86' } else { 'x64' }
                        Scope           = if ($path -like '*HKEY_CURRENT_USER*') { 'User' } else { 'Machine' }
                    }
                } catch {
                    # Skip keys we can't read
                }
            }
        } catch {
            # Path may not exist on some systems
        }
    }
    $items
}

function Get-InstalledSoftware {
    # Registry uninstall locations: machine/user, 64-bit/32-bit
    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    $regItems = Get-UninstallRegistryItems -RegistryPaths $paths

    # Deduplicate by Name + Version + Scope + Architecture
    $dedup = $regItems | Sort-Object Name, Version, Scope, Architecture -Unique

    $dedup
}

function Get-PackageSoftwareSafe {
    try {
        Get-Package -ErrorAction Stop | ForEach-Object {
            [PSCustomObject]@{
                Name            = $_.Name
                Version         = $_.Version.ToString()
                Publisher       = $_.ProviderName
                InstallDate     = $null
                UninstallString = $null
                InstallLocation = $null
                SystemComponent = $null
                ReleaseType     = $null
                Language        = $null
                Source          = "Get-Package:$($_.ProviderName)"
                Architecture    = $null
                Scope           = 'Unknown'
            }
        }
    } catch {
        @()
    }
}

# Main
$software = Get-InstalledSoftware

# Display in console
$software |
    Sort-Object Name |
    Select-Object Name, Version, Publisher, InstallDate, Architecture, Scope, InstallLocation, UninstallString |
    Format-Table -AutoSize
