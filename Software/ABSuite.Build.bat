call "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" -no_logo
cd /d C:\ABSuite\ABSF\trunk

PowerShell -Command "Add-LocalGroupMember -Group Administrators -Member AppAdminUser"
PowerShell -Command "Get-LocalGroupMember -Group Administrators"

fsutil.exe 8dot3name set C: 0
fsutil.exe 8dot3name query C:

MSBuild /t:build /p:Configuration=Debug /p:Platform=x64 IdChanger.slnf
MSBuild /t:build /p:Configuration=Debug /p:Platform=x64 Licensing.slnf
PUSHD Debug\bin64
LicensekeyGenerator.exe -eN -v1.0 -pWindows/MCP/OS2200
LicenseKeyInstaller.exe -v1.0
POPD

MSBuild /t:build /p:Configuration=Debug /p:Platform=x64 NGSystem.slnf

PUSHD "Runtime Infrastructure\Utility\Z_Install"
cscript ConfigureBuild.js AppUser Absuite@12345678 AppAdminUser Absuite@adm@12345678
POPD

MSBuild /t:restore /p:RestorePackagesConfig=true /p:Configuration=Debug /p:Platform=x64 Combined_CLR.slnf
MSBuild /t:build /p:Configuration=Debug /p:Platform=x64 Combined_CLR.slnf >Combined_CLR.log