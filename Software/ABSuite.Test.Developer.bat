PmodelTest.exe -nowait
ModelTest.exe -nowait
LCIFImportTest.exe -nowait
LanguageTest.exe -nowait
ConverterTest.exe -nowait
REM ATT
LicensingTest.exe -nowait
OS2200BuilderUnitTest.exe -nowait
CALL "Cut Scripts\Unit Test Scripts\UnitTestCS.bat"             Debug "C:\ABSuite\ABSF\trunk"
CALL "Cut Scripts\Unit Test Scripts\PainterUnitTest.bat"        Debug "C:\ABSuite\ABSF\trunk"
CALL "Cut Scripts\Unit Test Scripts\VersionControlUnitTest.bat" Debug "C:\ABSuite\ABSF\trunk"
CALL "Cut Scripts\Unit Test Scripts\LanguageServiceTest.bat"    Debug "C:\ABSuite\ABSF\trunk"