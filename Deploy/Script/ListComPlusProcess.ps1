# Lists: COM+ Applications and "Running COM+ Processes" (COM+ Explorer)
# Run in an elevated PowerShell if access is restricted.

$ErrorActionPreference = 'Stop'

function Get-ComPlusCatalog {
    try {
        return New-Object -ComObject COMAdmin.COMAdminCatalog
    } catch {
        throw "Failed to create COMAdmin.COMAdminCatalog. COM+ may not be installed/available in this image. $_"
    }
}

function Get-ComPlusApplications {
    param([Parameter(Mandatory)] $Catalog)

    $apps = $Catalog.GetCollection('Applications')
    $apps.Populate() | Out-Null

    $result = foreach ($app in $apps) {
        [pscustomobject]@{
            Name = $app.Value('Name')
            ID   = $app.Value('ID')
        }
    }

    $result | Sort-Object Name
}

function Get-ValueSafe {
    param(
        [Parameter(Mandatory)] $Item,
        [Parameter(Mandatory)] [string[]] $Names
    )
    foreach ($name in $Names) {
        try {
            $v = $Item.Value($name)
            if ($null -ne $v -and $v -ne '') { return $v }
        } catch { }
    }
    return $null
}

function Get-ComPlusRunningProcesses {
    param([Parameter(Mandatory)] $Catalog)

    # Build a lookup of Application ID -> Name to resolve descriptions
    $apps = $Catalog.GetCollection('Applications')
    $apps.Populate() | Out-Null
    $appById = @{}
    foreach ($app in $apps) {
        $id   = $app.Value('ID')
        $name = $app.Value('Name')
        if ($id) { $appById[$id] = $name }
    }

    $collectionName = 'RunningProcesses'
    try {
        $procs = $Catalog.GetCollection($collectionName)
        $procs.Populate() | Out-Null
    } catch {
        Write-Warning "Reading COM+ '$collectionName' failed: $($_.Exception.Message). Trying 'ApplicationInstances' fallback."
        $collectionName = 'ApplicationInstances'
        $procs = $Catalog.GetCollection($collectionName)
        $procs.Populate() | Out-Null
    }

    $result = @()
    for ($i = 0; $i -lt $procs.Count; $i++) {
        $p = $procs.Item($i)

        $procId = Get-ValueSafe -Item $p -Names @('ProcessID','PID')
        $appId  = Get-ValueSafe -Item $p -Names @('Application','ApplicationName','Name')
        $inst   = Get-ValueSafe -Item $p -Names @('ApplicationInstance','InstanceID','ID')

        # Resolve description from catalog by Application ID; fallback to any provided name fields
        $resolvedName = $null
        if ($appId -and $appById.ContainsKey($appId)) {
            $resolvedName = $appById[$appId]
        } else {
            $resolvedName = Get-ValueSafe -Item $p -Names @('ProcessName','Description','Name')
        }

        $result += [pscustomobject]@{
            ProcessID           = $procId
            Description         = $resolvedName
            Application         = $appId
            ApplicationInstance = $inst
            Source              = $collectionName
        }
    }

    $result | Sort-Object ProcessID
}

$catalog = Get-ComPlusCatalog

"=== COM+ Applications ==="
Get-ComPlusApplications -Catalog $catalog | Format-Table -AutoSize

"`n=== Running COM+ Processes ==="
try {
    $running = Get-ComPlusRunningProcesses -Catalog $catalog
    if (-not $running -or $running.Count -eq 0) {
        "(none)"
    } else {
        $running | Format-Table -AutoSize
    }
} catch {
    Write-Warning "Unable to read running COM+ processes: $($_.Exception.Message)"
    "(error; see warning above)"
}

"`nTip: If you don't see any running processes, start/activate a COM+ Server Application and rerun this script."