docker image inspect "ltsc2025:vs22" >$null
while ($LASTEXITCODE -ne 0) {
    Write-Host "Base image ltsc2025:vs22 not found locally. Building from Dockerfile..."
    docker system prune -f
    docker build -t ltsc2025:vs22 -m 8GB --no-cache -f .\Dockerfile.vs2022 .

    sleep -second 5
    docker image inspect "ltsc2025:vs22" >$null
}

# Write-Output "1. Download SQL Server 2022 installation media started."
# Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2215158" -OutFile "${env:TEMP}\\SQL2022-SSEI-Dev.exe"
# Write-Output "2. Download SQL Server 2022 installation offline files."
# $SQL2022_Download_Folder = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "SQL2022"
# $process = Start-Process -FilePath "${env:TEMP}\\SQL2022-SSEI-Dev.exe" -ArgumentList @('/ACTION=Download', "/MEDIAPATH=$SQL2022_Download_Folder", 'MEDIATYPE=ISO', '/QUIET') -PassThru -Wait -NoNewWindow;
# $process.WaitForExit();

docker image inspect "ltsc2025:vs22.sql22" >$null
while ($LASTEXITCODE -ne 0) {
    Write-Host "Base image ltsc2025:vs22.sql22 not found locally. Building from Dockerfile..."
    docker system prune -f
    docker build -t ltsc2025:vs22.sql22 -m 8GB --no-cache -f .\Dockerfile.SQL2022 .

    sleep -second 5
    docker image inspect "ltsc2025:vs22.sql22" >$null
}