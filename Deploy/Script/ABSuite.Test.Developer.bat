SET SourceDir=C:\ABSuite\ABSF\trunk
SET Configuration=Debug

if "%1" NEQ "" (SET SourceDir=%1)
if "%2" NEQ "" (SET Configuration=%2)

PmodelTest.exe -nowait
ModelTest.exe -nowait
LCIFImportTest.exe -nowait
LanguageTest.exe -nowait
ConverterTest.exe -nowait
REM ATT
LicensingTest.exe -nowait
OS2200BuilderUnitTest.exe -nowait
CALL "Cut Scripts\Unit Test Scripts\UnitTestCS.bat"             %Configuration% "%SourceDir%"
CALL "Cut Scripts\Unit Test Scripts\PainterUnitTest.bat"        %Configuration% "%SourceDir%"
CALL "Cut Scripts\Unit Test Scripts\VersionControlUnitTest.bat" %Configuration% "%SourceDir%"
CALL "Cut Scripts\Unit Test Scripts\LanguageServiceTest.bat"    %Configuration% "%SourceDir%"