# AB Suite Containerization with Visual Studio 2022 BuildTools

## Notes
This project aims for supporting containerized building and testing with Visual Studio 2022 BuildTools only.
### Known Issues
AB Suite requires code changes to ensure build compatibility with Visual Studio Build Tools 2022 (not full Visual Studio). Key changes are yet to be applied in trunk.
- Enhance VSWhere detection
- Handle absence of devenv.exe
- Skip VS extension deployment

## Checkout AB Suite Source (On Host OS)
- **<font color="red">Make sure VPN is connected.</font>**
- svn checkout https://ustr-svn-1.na.uis.unisys.com/ABSuite/ABSF/trunk C:\ABSuite\ABSF\trunk

## Build Docker Image (On Host OS)
- **<font color="red">Make sure VPN is NOT connected.</font>**
- Open a PowerShell Command Prompt:
- Set-Location ${env:UserProfile}\Documents
- git clone https://ustr-bitbucket-1.na.uis.unisys.com:8443/scm/~huangcf/abs-devops.git
- Set-Location abs-devops
- .\Deploy\Script\DockerImage.Build.ps1 -docker_file .\Dockerfile.ABSuite.Dev -image_tag absuite:dev

## Create a Container (On Host OS)
- docker run -it -d --name absuite-dev -v C:\ABSuite\ABSF\trunk:C:\ABSuite\ABSF\trunk absuite:dev
- docker exec -it absuite-dev cmd

## Build AB Suite Source (In Container)
- C:\Deploy\Script\ABSuite.Dev.Build.bat C:\ABSuite\ABSF\trunk Debug Combined_ABSuite.sln

## Run AB Suite Unit Tests (E.g., ModelTest.exe)
- cd /d C:\ABSuite\ABSF\trunk\Debug\bin64
- ModelTest.exe -nowait