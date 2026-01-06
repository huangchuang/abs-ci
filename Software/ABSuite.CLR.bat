CALL "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat"

regsvr32.exe /s C:\ABSuite\Debug\bin64\SecurityUtilities.dll

PUSHD "C:\ABSuite\Runtime Infrastructure\Utility\Z_Install"
cscript.exe ConfigureBuild.js AppUser Absuite@12345678 AppAdminUser Absuite@adm@12345678
cscript.exe //nologo //D BuildOnlyInstall.wsf /InstallFolder:"C:\ABSuite\Debug" /SourceFolder:"C:\ABSuite\" /Install+ /Debug+
POPD

PUSHD "C:\ABSuite\Debug\bin64"
.\RegisterNGEN.bat C:\ABSuite Debug
.\GeneratePrototypedApp.bat C:\ABSuite\Debug\bin64
POPD