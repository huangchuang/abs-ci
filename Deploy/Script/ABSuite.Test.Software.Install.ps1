function Install-ApacheAnt {
    Write-Output "Install Apache Ant started."
    $version="1.10.15"
    $url = ('https://dlcdn.apache.org//ant/binaries/apache-ant-{0}-bin.zip' -f $version)
    Write-Output "Downloading Apache Ant from $url"
    Invoke-WebRequest -Uri $url -OutFile 'apache-ant.zip'
    Write-Output "Extracting Apache Ant to C:\"
    Expand-Archive -Path 'apache-ant.zip' -DestinationPath 'C:\' -Force
    Remove-Item -Path 'apache-ant.zip' -Force
    Write-Output "Install Apache Ant succeeded."
}

Install-ApacheAnt