SET SourceDir=C:\ABSuite\ABSF\trunk
SET Configuration=Debug
SET Solution=Combined_ABSuite.sln

if "%1" NEQ "" (SET SourceDir=%1)
if "%2" NEQ "" (SET Configuration=%2)
if "%3" NEQ "" (SET Solution=%3)


call "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" -no_logo
cd /d %SourceDir%

fsutil.exe 8dot3name set 0
fsutil.exe 8dot3name set C: 0
fsutil.exe 8dot3name query C:

MSBuild /t:build /p:Configuration=%Configuration% /p:Platform=x64 IdChanger.slnf
MSBuild /t:build /p:Configuration=%Configuration% /p:Platform=x64 Licensing.slnf
PUSHD %Configuration%\bin64
LicensekeyGenerator.exe -eN -v1.0 -pWindows/MCP/OS2200
LicenseKeyInstaller.exe -v1.0
POPD

MSBuild /t:build /p:Configuration=%Configuration% /p:Platform=x64 NGSystem.slnf

PUSHD "Runtime Infrastructure\Utility\Z_Install"
cscript ConfigureBuild.js AppUser Absuite@12345678 AppAdminUser Absuite@adm@12345678
POPD

MSBuild /t:restore /p:RestorePackagesConfig=true /p:Configuration=%Configuration% /p:Platform=x64 %Solution%
MSBuild /t:build /p:Configuration=%Configuration% /p:Platform=x64 %Solution% >%Solution%.log