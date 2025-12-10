# Usage
# .\Software\Build.ps1 -docker_file .\Dockerfile.VS2022  -image_tag ltsc2025:vs22
# .\Software\Build.ps1 -docker_file .\Dockerfile.SQL2022 -image_tag ltsc2025:vs22.sql22
# .\Software\Build.ps1 -docker_file .\Dockerfile         -image_tag ltsc2025:vs22.sql22

param(
    [string]$docker_file,
    [string]$image_tag
)

$attempt=0
docker image inspect "${image_tag}" >$null
while ($LASTEXITCODE -ne 0) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $attempt = $attempt + 1
    Write-Host "Round ${attempt} started - ${now}: Base image ${image_tag} not found locally. Building from Dockerfile..."
    docker system prune -f
    docker build -t "${image_tag}" -m 16GB --no-cache -f $docker_file .

    sleep -second 5
    docker image inspect "${image_tag}" >$null
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Round ${attempt} ended - ${now}"
}