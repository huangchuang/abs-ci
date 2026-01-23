
rem This jar file can be used to sign the generated signed jar file for presentation client. 
rem This has to be udpated based on the certificate used by user. 
rem The Certificate provider should also provide Storetype, Storepass, Keystore and alias name along with the Certificate.

rem Certificate location
set certificateLocation=C:\NGEN_CE\Classes

rem Storetype for certificate
set storeType=xxxx

rem Storepass for cetificate
set pass="********"

rem keystore for certificate
set keyStore=xxxxxxxx.keystore

rem Alias name for certificate
set aliasname=xxxxxxxxx


rem required bundle jar to sign along with fullpath 
rem if File available in C:\NGEN_CE\classes location and file name is sample.jar, then use full path as "C:\NGEN_CE\classes\sample.jar"
set jarname=<Jar location>\<jar file name with extension>


jarsigner -storetype %storeType% -storepass %pass% -keystore %certificateLocation%\%keyStore% %jarname% %aliasname%