@ECHO OFF
REM To Copy the axbridge files to JRE home folder, given the path of JRE home.
REM NOTE: Custom Generators for Java 1.8 or higher are not supported as Active-X Bridge is no longer supported from Java 1.8 onwards. 
REM (c) Copyright 2016-2017 - Unisys Corporation - do not distribute withour prior permission from Unisys.

SETLOCAL ENABLEEXTENSIONS
REM Save the script name and the parent dir
SET scriptname=%~0
SET parentdir=%~dp0
SET usagestr=Usage= %scriptname% "Source_of_axbridge" "JRE_HOME_VERSION_1.7_OR_LESS" 

SET source="%1"
IF "%source:"=.%"==".." (
	REM User must specify Source
	SET ErrorString=Error in parameters: %usagestr%
	GOTO FATALERROR
)

SET dest="%2"
IF "%dest:"=.%"==".." (
	REM User must specify JRE_HOME
	SET ErrorString=Error in parameters: %usagestr%
	GOTO FATALERROR
)

SET dest=%dest%\axbridge

ECHO Copying the Files from %source% to %dest%
xcopy /I /Y /E /F /C "%source%" "%dest%"
GOTO EXIT

:FATALERROR
ECHO.
ECHO %ErrorString%
ECHO E.g. filename.bat "D:\CE_CD\axbridge" "C:\Program Files\Java\jre6"
ECHO.

:EXIT
CD /D %parentdir%


