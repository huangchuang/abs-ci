# AB Suite Docker Build
## Build Image (On Host)
PS abs-ci> .\Software\Build.ps1 -dockerfile .\Dockerfile         -image_tag ltsc2025:vs22.sql22

## Run Container (On Host)
PS abs-ci> docker run -it -d --isolation=process --name absuite -v C:\ABSuite\abs-ci\trunk:C:\ABSuite\ABSF\trunk ltsc2025:vs22.sql22

## Build AB Suite (In Container)
- Open the terminal prompt of the launched **absuite** container 
- Launch the Visual Studio Build Tools 2022 Command Prompt
    - C:\TEMP>"C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
- Switch to the AB Suite source directory
    - C:\TEMP> cd /d C:\ABSuite\ABSF\trunk
- Build the AB Suite source
    - C:\ABSuite\absf\trunk> MSBuild /t:restore /p:RestorePackagesConfig=true /p:Configuration=Debug /p:Platform=x64 Combined_SystemModeler.slnf
        - Notes: Remove the container and recreating it by removing the **--isolation=process** option if you see weird "msbuild /t:restore" errors below:
        - **C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\NuGet\NuGet.targets(178,5): error : Could not find a part of the part. [C:\ABSuite\ABSF\trunk\Combined_SystemModeler.slnf]**
    - C:\ABSuite\absf\trunk> MSBuild /t:build /p:Configuration=Debug /p:Platform=x64 Combined_SystemModeler.slnf