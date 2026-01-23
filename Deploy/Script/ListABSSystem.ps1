# Constants
$RUNTIMEMANAGER_PROGID = "RuntimeManager.RuntimeData.10.0.1"

# Function definition
function Check-Systems {
    $rData = New-Object -ComObject $RUNTIMEMANAGER_PROGID
    $systems = $rData.ListSystems("", "")

    Write-Output "Total systems found: $($systems.Count)"
    foreach ($system in $systems) {
        Write-Output "    $system"
    }
}

function Check-Databases {
    $rData = New-Object -ComObject $RUNTIMEMANAGER_PROGID
    $databases = $rData.ListDatabases("default")

    Write-Output "Total databases found: $($databases.Count)"
    foreach ($database in $databases) {
        Write-Output "    $database"
    }
}

function Check-DBMSAliases {
    $rData = New-Object -ComObject $RUNTIMEMANAGER_PROGID
    $aliases = $rData.ListDBMSAliases()

    Write-Output "Total DBMS aliases found: $($aliases.Count)"
    foreach ($alias in $aliases) {
        Write-Output "    $alias"
    }
}

Check-Systems
Check-Databases
Check-DBMSAliases