# This script demonstrates how to access and process command-line arguments in PowerShell.

# The automatic variable $args is an array that contains all arguments passed to the script.
# We can check its length (or count) to see how many arguments were provided.
$argCount = $args.Count
Write-Host "Number of arguments received: $argCount"

# Check if any arguments were passed before trying to loop through them.
if ($argCount -gt 0) {
    $i = 0
    foreach ($arg in $args) {
        Write-Host "  Arg[$i]: $arg"
        $i++
    }
} else {
    Write-Host "No arguments were provided."
}

exit 0