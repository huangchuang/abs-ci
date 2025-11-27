# Usage
# .\build.ps1 -dockefile .\Dockerfile.VS2022 -image_tag ltsc2025:vs22
# .\build.ps1 -dockefile .\Dockerfile.SQL2022 -image_tag ltsc2025:vs22.sql22

param(
    [string]$dockefile,
    [string]$image_tag
)

$attempt=0
docker image inspect "${dockerfile}" >$null
while ($LASTEXITCODE -ne 0) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $attempt = $attempt + 1
    Write-Host "Round ${attempt} started - ${now}: Base image ${image_tag} not found locally. Building from Dockerfile..."
    docker system prune -f
    docker build -t "${image_tag}" -m 8GB --no-cache -f $dockefile .

    sleep -second 5
    docker image inspect "${dockerfile}" >$null
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Round ${attempt} ended - ${now}"
}