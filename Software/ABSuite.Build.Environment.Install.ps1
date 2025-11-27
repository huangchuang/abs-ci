function CreateUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $username = 'DoudouUser',

        [Parameter(Mandatory=$false)]
        [string] $description = 'AB Suite Application User',

        [Parameter(Mandatory=$false)]
        [string] $plainPassword = 'Doudou1User@docker@0694'
    )

    # Convert to secure string
    $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    # Check if user exists
    $existing = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    if (-not $existing) {
        # Create user with requested settings
        New-LocalUser `
            -Name $username `
            -Password $securePassword `
            -Description $description `
            -PasswordNeverExpires

        Write-Host "Created local user '$username'."
    } else {
        # Ensure description
        if ($existing.Description -ne $description) {
            Set-LocalUser -Name $username -Description $description
            Write-Host "Updated description for '$username'."
        }

        # Ensure PasswordNeverExpires
        Set-LocalUser -Name $username -PasswordNeverExpires:$true

        # Optionally reset password to the specified one (only if needed)
        try {
            # Always set the password to the provided value to ensure correctness
            Set-LocalUser -Name $username -Password $securePassword
            Write-Host "Ensured password and settings for '$username'."
        } catch {
            Write-Warning "Failed to set password for '$username': $($_.Exception.Message)"
        }
    }
}

function CreateUsers {
    CreateUser -username 'DoudouUser' -description 'Doudou Application User' -plainPassword 'Doudou1User@docker@0694'
    CreateUser -username 'DoudouAdminUser' -description 'Doudou Admin User' -plainPassword 'Doudou1AdminUser@docker@0694'
}

# --- Helpers ---
function Assert-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This operation requires Administrator privileges. Please run PowerShell elevated."
    }
}

function Get-UserSid {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Username
    )
    $nt = New-Object System.Security.Principal.NTAccount("$env:COMPUTERNAME", $Username)
    try {
        return $nt.Translate([System.Security.Principal.SecurityIdentifier]).Value
    } catch {
        throw "User '$env:COMPUTERNAME\\$Username' not found."
    }
}

function Export-UserRightsInf {
    param(
        [Parameter(Mandatory=$true)] [string] $Path
    )
    secedit /export /cfg "$Path" /areas USER_RIGHTS | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Path)) {
        throw "Failed to export Local Security Policy (USER_RIGHTS). ExitCode=$LASTEXITCODE"
    }
}

function Parse-PrivilegeRights {
    param(
        [Parameter(Mandatory=$true)] [string] $InfPath
    )
    $lines = Get-Content -LiteralPath $InfPath -ErrorAction Stop
    $rightsTable = @{}
    $inSection = $false
    foreach ($line in $lines) {
        if ($line -match '^\[Privilege Rights\]') { $inSection = $true; continue }
        if ($inSection -and $line -match '^\[') { $inSection = $false }
        if ($inSection -and $line -match '^(\S+)\s*=\s*(.*)$') {
            $name = $Matches[1]
            $val = $Matches[2]
            $entries = ($val -split ',\s*') | Where-Object { $_ -ne '' }
            # Normalize: strip leading '*' from SIDs so we compare consistently
            $normalized = @()
            foreach ($e in $entries) {
                $trim = $e.Trim()
                if ($trim -match '^\*S-') {
                    $normalized += $trim.Substring(1)
                } else {
                    $normalized += $trim
                }
            }
            $rightsTable[$name] = $normalized
        }
    }
    return $rightsTable
}

function Verify-UserRights {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $Username,
        [Parameter(Mandatory=$true)] [string[]] $Rights
    )

    $sid = Get-UserSid -Username $Username
    $tempDir = [System.IO.Path]::GetTempPath()
    $infPath = Join-Path $tempDir 'absuite-user-rights-verify.inf'
    Export-UserRightsInf -Path $infPath
    $rightsTable = Parse-PrivilegeRights -InfPath $infPath

    $missing = @()
    foreach ($r in $Rights) {
        if (-not $rightsTable.ContainsKey($r) -or -not ($rightsTable[$r] -contains $sid)) {
            $missing += $r
        }
    }
    return [PSCustomObject]@{ Username = $Username; Sid = $sid; MissingRights = $missing }
}

function GrantUserRights {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $Username,

        [Parameter(Mandatory=$true)]
        [string[]] $Rights
    )

    Assert-Admin

    # Resolve the local account to SID
    try { $sid = Get-UserSid -Username $Username } catch { Write-Error $_; return $false }

    $tempDir = [System.IO.Path]::GetTempPath()
    $infPath = Join-Path $tempDir 'absuite-user-rights.inf'
    $dbPath = Join-Path $tempDir 'absuite-secedit.sdb'

    # Export current policy
    try { Export-UserRightsInf -Path $infPath } catch { Write-Error $_; return $false }

    # Load and normalize INF content
    $lines = Get-Content -LiteralPath $infPath -ErrorAction Stop
    if (-not ($lines | Where-Object { $_ -match '^\[Privilege Rights\]' })) {
        $lines += '[Privilege Rights]'
    }

    # Build a hashtable of current assignments
    $rightsTable = @{}
    $inSection = $false
    foreach ($line in $lines) {
        if ($line -match '^\[Privilege Rights\]') { $inSection = $true; continue }
        if ($inSection -and $line -match '^\[') { $inSection = $false }
        if ($inSection -and $line -match '^(\S+)\s*=\s*(.*)$') {
            $name = $Matches[1]
            $val = $Matches[2]
            $rightsTable[$name] = ($val -split ',\s*') | Where-Object { $_ -ne '' }
        }
    }

    # Ensure each requested right includes the SID
    foreach ($right in $Rights) {
        if (-not $rightsTable.ContainsKey($right)) {
            $rightsTable[$right] = @()
        }
        if (-not ($rightsTable[$right] -contains $sid)) {
            $rightsTable[$right] += $sid
        }
    }

    # Reconstruct the INF file
    $preSection = @()
    $postSection = @()
    $inSection = $false
    foreach ($line in $lines) {
        if ($line -match '^\[Privilege Rights\]') { $inSection = $true; $preSection += $line; continue }
        if ($inSection) { continue }
        $preSection += $line
    }

    $out = @()
    $wroteSection = $false
    foreach ($l in $preSection) {
        $out += $l
        if ($l -match '^\[Privilege Rights\]') {
            $wroteSection = $true
            foreach ($k in ($rightsTable.Keys | Sort-Object)) {
                # Re-add '*' to SIDs, keep non-SID values as-is
                $vals = @()
                foreach ($v in $rightsTable[$k]) {
                    if ($v -match '^S-') { $vals += ('*' + $v) } else { $vals += $v }
                }
                $out += "$k = " + ($vals -join ',')
            }
        }
    }
    if (-not $wroteSection) {
        $out += '[Privilege Rights]'
        foreach ($k in ($rightsTable.Keys | Sort-Object)) {
            $vals2 = @()
            foreach ($v in $rightsTable[$k]) {
                if ($v -match '^S-') { $vals2 += ('*' + $v) } else { $vals2 += $v }
            }
            $out += "$k = " + ($vals2 -join ',')
        }
    }

    Set-Content -LiteralPath $infPath -Value $out -Encoding ASCII

    # Apply updated policy (may require elevation)
    secedit /configure /db "$dbPath" /cfg "$infPath" /areas USER_RIGHTS | Out-Null
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
        Write-Error "secedit /configure failed with ExitCode=$exit"
        return $false
    }
    try { gpupdate /target:computer /force | Out-Null } catch { Write-Warning "gpupdate failed: $($_.Exception.Message)" }

    # Verify
    $result = Verify-UserRights -Username $Username -Rights $Rights
    if ($result.MissingRights.Count -gt 0) {
        # Retry once
        Write-Warning "Rights not fully applied for '$Username'. Retrying once... Missing: $($result.MissingRights -join ', ')"
        secedit /configure /db "$dbPath" /cfg "$infPath" /areas USER_RIGHTS | Out-Null
        $exit2 = $LASTEXITCODE
        if ($exit2 -ne 0) {
            Write-Error "Second secedit attempt failed with ExitCode=$exit2"
            return $false
        }
        try { gpupdate /target:computer /force | Out-Null } catch { }
        $result = Verify-UserRights -Username $Username -Rights $Rights
    }

    if ($result.MissingRights.Count -gt 0) {
        Write-Error "Failed to grant rights to '$env:COMPUTERNAME\\$Username'. Missing: $($result.MissingRights -join ', ')"
        return $false
    } else {
        Write-Host "Granted rights to '$env:COMPUTERNAME\\$Username': $($Rights -join ', ')"
        return $true
    }
}

function AddPrivilegeToAppUser {
    param(
        [Parameter(Mandatory=$false)]
        [string] $username = 'AppUser'
    )

    $ok = GrantUserRights -Username $username -Rights @(
        'SeNetworkLogonRight',      # Access this computer from the network
        'SeTcbPrivilege',           # Act as part of the operating system
        'SeInteractiveLogonRight',  # Allow logon locally
        'SeBatchLogonRight',        # Log on as a batch job
        'SeServiceLogonRight'       # Log on as a service (additional for AppUser)
    )
    if (-not $ok) {
        throw "Failed to grant required rights for user '$username'"
    }
}

function AddPrivilegeToAppAdminUser {
    param(
        [Parameter(Mandatory=$false)]
        [string] $username = 'AppAdminUser'
    )

    $ok = GrantUserRights -Username $username -Rights @(
        'SeNetworkLogonRight',      # Access this computer from the network
        'SeTcbPrivilege',           # Act as part of the operating system
        'SeInteractiveLogonRight',  # Allow logon locally
        'SeBatchLogonRight',        # Log on as a batch job
        'SeAssignPrimaryTokenPrivilege' # Replace a process level token (additional for AppAdminUser)
    )
    if (-not $ok) {
        throw "Failed to grant required rights for user '$username'"
    }
}

function CreateSQLLogins {
    
}

CreateUsers

# Ensure security rights for the application accounts
AddPrivilegeToAppUser -username 'DoudouUser'
AddPrivilegeToAppAdminUser -username 'DoudouAdminUser'