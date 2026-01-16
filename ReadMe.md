# AB Suite Docker Build
## Build Image (On Host)
PS abs-ci> .\Software\DockerImage.Build.ps1 -docker_file .\Dockerfile.ABSuite.Dev         -image_tag absuite:dev
PS abs-ci> .\Software\DockerImage.Build.ps1 -docker_file .\Dockerfile.ABSuite.Test        -image_tag absuite:test

## Run Container (On Host)
PS abs-ci> docker run -it -d --isolation=process --name absuite -v C:\ABSuite\ABSF\trunk:C:\ABSuite\ABSF\trunk -v C:\Users\HuangCF\Documents\abs-ci:C:\abs-ci absuite:dev

## Build AB Suite (In Container)
- Open the terminal prompt of the launched **absuite** container 
- Launch the Visual Studio Build Tools 2022 Command Prompt
    - C:\TEMP>C:\abs-ci\Software\ABSuite.Dev.Build.bat

## Notes
Remove the container and recreating it without using the **--isolation=process** option if you see weird "msbuild /t:restore" errors below:
**C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\NuGet\NuGet.targets(178,5): error : Could not find a part of the part. [C:\ABSuite\ABSF\trunk\Combined_SystemModeler.slnf]**