SET SourceDir=C:\ABSuite\ABSF\trunk
SET Configuration=Debug

if "%1" NEQ "" (SET SourceDir=%1)
if "%2" NEQ "" (SET Configuration=%2)

CALL "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"

regsvr32.exe /s %SourceDir%\%Configuration%\bin64\SecurityUtilities.dll

PUSHD "%SourceDir%\Runtime Infrastructure\Utility\Z_Install"
cscript.exe ConfigureBuild.js AppUser Absuite@12345678 AppAdminUser Absuite@adm@12345678
POPD

PUSHD "%SourceDir%\Cut Scripts\Unit Test Scripts"
CALL RegisterNGEN.bat %SourceDir% %Configuration%
POPD

PUSHD "%SourceDir%\System Modeler"
ECHO Starting to register Unisys keys...
CALL RegisterUnisysKeys.bat %SourceDir%\%Configuration%\
POPD

PUSHD "%SourceDir%\%Configuration%\bin64"
ECHO Starting to generate prototyped applications...
REM Enable8dot3Name on C: drive
fsutil.exe 8dot3name set 0
fsutil.exe 8dot3name set C: 0
fsutil.exe 8dot3name query C:
MKDIR C:\Windows\Installer
CALL GeneratePrototypedApp.bat %SourceDir%\%Configuration%\bin64
POPD