# Usage
# .\Software\DockerImage.Build.ps1 -docker_file .\Dockerfile.ABSuite.Dev -image_tag absuite:dev

param(
    [string]$docker_file,
    [string]$image_tag
)

$attempt=0
docker image rm "${image_tag}" -f 2>$null
docker image inspect "${image_tag}" 2>$null
while ($LASTEXITCODE -ne 0) {
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $attempt = $attempt + 1
    Write-Host "Round ${attempt} started - ${now}: Base image ${image_tag} not found locally. Building from Dockerfile..."
    docker system prune -f
    docker build -t "${image_tag}" -m 16GB --no-cache -f $docker_file .

    Start-Sleep -Seconds 5
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Round ${attempt} ended - ${now}"
    docker image inspect "${image_tag}" 2>$null
}