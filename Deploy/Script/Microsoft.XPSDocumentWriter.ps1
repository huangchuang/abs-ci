# TODO: This script is not working in the container because the XPS Document Writer printer is not installed there.

function Check-XPSDocumentWriterDefault {
    # Check if "Microsoft XPS Document Writer" is the default printer
    $targetName = "Microsoft XPS Document Writer"

    $printer = Get-CimInstance -ClassName Win32_Printer -Filter ("Name='{0}'" -f $targetName.Replace("'", "''")) -ErrorAction SilentlyContinue

    if (-not $printer) {
        Write-Error "Printer '$targetName' not found."
    }
    else {
        if ($printer.Default) {
            Write-Host "XPS Document Writer is the default printer."
        }
        else {
            Write-Error "XPS Document Writer is not the default printer."
        }
    }
}

Check-XPSDocumentWriterDefault