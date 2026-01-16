CALL "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"

regsvr32.exe /s C:\ABSuite\ABSF\trunk\Debug\bin64\SecurityUtilities.dll

PUSHD "C:\ABSuite\ABSF\trunk\Runtime Infrastructure\Utility\Z_Install"
cscript.exe ConfigureBuild.js AppUser Absuite@12345678 AppAdminUser Absuite@adm@12345678
POPD

PUSHD "C:\ABSuite\ABSF\trunk\Cut Scripts\Unit Test Scripts"
CALL RegisterNGEN.bat C:\ABSuite\ABSF\trunk Debug
POPD

PUSHD "C:\ABSuite\ABSF\trunk\System Modeler"
ECHO Starting to register Unisys keys...
CALL RegisterUnisysKeys.bat C:\ABSuite\ABSF\trunk\Debug\
POPD

PUSHD "C:\ABSuite\ABSF\trunk\Debug\bin64"
ECHO Starting to generate prototyped applications...
REM Enable8dot3Name on C: drive
fsutil.exe 8dot3name set 0
fsutil.exe 8dot3name set C: 0
fsutil.exe 8dot3name query C:
MKDIR C:\Windows\Installer
CALL GeneratePrototypedApp.bat C:\ABSuite\ABSF\trunk\Debug\bin64
POPD