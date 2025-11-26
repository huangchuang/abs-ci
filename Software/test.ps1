# # This script demonstrates how to access and process command-line arguments in PowerShell.

# # The automatic variable $args is an array that contains all arguments passed to the script.
# # We can check its length (or count) to see how many arguments were provided.
# $argCount = $args.Count
# Write-Host "Number of arguments received: $argCount"

# # Check if any arguments were passed before trying to loop through them.
# if ($argCount -gt 0) {
#     $i = 0
#     foreach ($arg in $args) {
#         Write-Host "  Arg[$i]: $arg"
#         $i++
#     }
# } else {
#     Write-Host "No arguments were provided."
# }

# exit 0
$now = Get-Date -Format "yyyyMMdd HHmmss"; Write-Output "1 $now";
docker build -t ltsc2025:vs22         -m 8GB -f Dockerfile.VS2022 .

$now = Get-Date -Format "yyyyMMdd HHmmss"; Write-Output "2 $now";
docker build -t ltsc2025:vs22.sql22 -m 8GB -f Dockerfile.SQL2022 .

$now = Get-Date -Format "yyyyMMdd HHmmss"; Write-Output "3 $now";
docker run -it -d --name test-vs22-sql22 --mount=type=bind,source=D:\ABSuite\abs-ci\trunk,target=C:\ABSuite\ABSF\trunk --entrypoint "cmd.exe" ltsc2025:vs22.sql22 cmd /K "echo Hello AB Suite"