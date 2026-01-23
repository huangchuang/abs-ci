param(
    [Parameter(Mandatory = $true)]
    [string]$DeployFolder
)

$global:DeployFolder = $DeployFolder

$appUserName = 'AppUser'
$appUserPassword = 'Absuite@12345678'
$appAdminUserName = 'AppAdminUser'
$appAdminUserPassword = 'Absuite@adm@12345678'

function CreateUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $username = $appUserName,

        [Parameter(Mandatory=$false)]
        [string] $description = 'AB Suite Application User',

        [Parameter(Mandatory=$false)]
        [string] $plainPassword = $appUserPassword
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
    CreateUser -username $appUserName -description 'App Application User' -plainPassword $appUserPassword
    CreateUser -username $appAdminUserName -description 'App Admin User' -plainPassword $appAdminUserPassword
    Add-LocalGroupMember -Group "Administrators" -Member $appAdminUserName
}

function Enable8dot3Name {
    & fsutil.exe 8dot3name set 0
    & fsutil.exe 8dot3name set C: 0
    & fsutil.exe 8dot3name query C:
}

# --- Helpers ---
function Assert-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This operation requires Administrator privileges. Please run PowerShell elevated."
    }
}

function AddPrivilegeToAppUser {
    param(
        [Parameter(Mandatory=$false)]
        [string] $username = 'AppUser'
    )

    $rights = @(
        'SeServiceLogonRight',      # Log on as a service (for service accounts)
        'SeNetworkLogonRight',      # Access this computer from the network
        'SeTcbPrivilege',           # Act as part of the operating system
        'SeInteractiveLogonRight',  # Allow logon locally
        'SeBatchLogonRight'         # Log on as a batch job
    )

    Assert-Admin

    . (Join-Path $PSScriptRoot 'LsaUtility.ps1')

    Write-Host "Old security policy rights:"
    Check-Right -AccountName $username

    foreach ($right in $rights) {
        Set-Right -AccountName $username -PrivilegeName $right
    }

    Write-Host "New security policy rights:"
    Check-Right -AccountName $username
}

function AddPrivilegeToAppAdminUser {
    param(
        [Parameter(Mandatory=$false)]
        [string] $username = 'AppAdminUser'
    )

    $rights = @(
        'SeAssignPrimaryTokenPrivilege', # Replace a process level token
        'SeNetworkLogonRight',      # Access this computer from the network
        'SeTcbPrivilege',           # Act as part of the operating system
        'SeInteractiveLogonRight',  # Allow logon locally
        'SeBatchLogonRight'         # Log on as a batch job
    )

    Assert-Admin

    . (Join-Path $PSScriptRoot 'LsaUtility.ps1')

    Write-Host "Old security policy rights:"
    Check-Right -AccountName $username
    
    foreach ($right in $rights) {
        Set-Right -AccountName $username -PrivilegeName $right
    }

    Write-Host "New security policy rights:"
    Check-Right -AccountName $username
}

function CreateSQLLogins {
    [CmdletBinding()]
    param(
        # Default to the local, default instance for SQL Developer Edition
        [Parameter(Mandatory=$false)]
        [string]$SQLInstance = "." 
    )

    try {
        # Ensure the SqlServer module is available
        if (-not (Get-Module -ListAvailable -Name SqlServer)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Install-Module -Name SqlServer -AllowClobber -Force
            if (-not (Get-Module -ListAvailable -Name SqlServer)) {
                Write-Host "SqlServer module not found. Please install it first by running: Install-Module -Name SqlServer"
                return
            }
        }
        Import-Module SqlServer -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to load the SqlServer module. Please ensure it is installed and try again."
        return
    }

    # Use the computer name for Windows integrated logins
    $computerName = $env:COMPUTERNAME
    $appUserLogin = "$computerName\$appUserName"
    $appAdminUserLogin = "$computerName\$appAdminUserName"

    $logins = @(
        @{ Name = $appUserLogin; IsAdmin = $false },
        @{ Name = $appAdminUserLogin; IsAdmin = $true }
    )

    foreach ($login in $logins) {
        $loginName = $login.Name
        try {
            Write-Host "Processing SQL login for '$loginName' on instance '$SQLInstance'..."

            # Check if the login already exists
            if (-not (Get-SqlLogin -ServerInstance $SQLInstance -LoginName $loginName -TrustServerCertificate -ErrorAction SilentlyContinue)) {
                Write-Host "Login '$loginName' does not exist. Creating..."
                $createQuery = "CREATE LOGIN [$loginName] FROM WINDOWS WITH DEFAULT_DATABASE=[master]"
                Invoke-Sqlcmd -ServerInstance $SQLInstance -Query $createQuery -TrustServerCertificate
                Write-Host "Successfully created login '$loginName'."
            } else {
                Write-Host "Login '$loginName' already exists."
            }

            # Grant server roles to the admin user
            if ($login.IsAdmin) {
                Write-Host "Assigning server roles to admin user '$loginName'..."
                # 'public' is granted by default.
                $adminRoles = @('sysadmin', 'serveradmin') 
                foreach ($role in $adminRoles) {
                    # Check if the login is already a member of the role
                    $checkQuery = "
                        SELECT 1
                        FROM sys.server_role_members rm
                        JOIN sys.server_principals rp ON rm.role_principal_id = rp.principal_id
                        JOIN sys.server_principals mp ON rm.member_principal_id = mp.principal_id
                        WHERE rp.name = '$role' AND mp.name = '$loginName'"
                    $isMember = Invoke-Sqlcmd -ServerInstance $SQLInstance -Query $checkQuery -TrustServerCertificate
                    if ($isMember.Column1 -ne 1) {
                        Write-Host "Adding '$loginName' to the '$role' server role."
                        Invoke-Sqlcmd -ServerInstance $SQLInstance -Query "ALTER SERVER ROLE [$role] ADD MEMBER [$loginName]" -TrustServerCertificate
                        Write-Host "Successfully added '$loginName' to '$role'."
                    } else {
                        Write-Host "'$loginName' is already a member of the '$role' role."
                    }
                }
            }
        }
        catch {
            Write-Error "An error occurred while processing login '$loginName': $($_.Exception.Message)"
        }
    }

    # Restart SQL Server to apply changes
    Write-Host "Restarting SQL Server service (MSSQLSERVER)..."
    try {
        Restart-Service -Name "MSSQLSERVER" -Force -ErrorAction Stop
        # Wait for the service to be fully running
        $service = Get-Service -Name "MSSQLSERVER"
        $service.WaitForStatus('Running', (New-TimeSpan -Seconds 30))
        Write-Host "SQL Server service has been restarted successfully."
    }
    catch {
        Write-Error "Failed to restart SQL Server service. Please check the service name and ensure you are running with Administrator privileges. Error: $($_.Exception.Message)"
    }
}

function Install-Fonts {
    Write-Host "Install Fonts started."
    & "${global:DeployFolder}\Script\ABSuite.Test.Install.Fonts.ps1" -font_dir "${global:DeployFolder}\Software\Fonts"
    Write-Host "Install Fonts succeeded, exit: $exit"
}

# Ensure security rights for the application accounts
CreateUsers
AddPrivilegeToAppUser -username $appUserName
AddPrivilegeToAppAdminUser -username $appAdminUserName

# Create the SQL Logins
CreateSQLLogins

Enable8dot3Name

# Fonts are required for running unit tests
Install-Fonts