@ECHO OFF
:BEGIN
echo --- Procedure start ---
REM Set variables
set QMGR1=QM1SEC
set QMGR2=QM2SEC
set QMGR1PORT=9005
set QMGR2PORT=9006
REM It should be the user used by your client
set USER=app
REM This variable is used to name the client key DB, cert label and cert file
Set MYCLIENT=MyClient
REM Location where certificates will be be stored (also set at QMGR level)
set CERTLOC=C:\MyCertificates
set MQCHLLIBLOC=C:\ProgramData\IBM\MQ\qmgrs

for /F "tokens=* USEBACKQ" %%F IN (`dspmqver -f2`) DO ( set MQVER=%%F )
set MQVER=%MQVER:.=%
FOR %%A IN (%MQVER%) DO set MQVER=%%A
REM Below SSLCIPH will be set according to the test results we see
REM MQ 9.1.0.5:  SSLCIPH = ECDHE_RSA_AES_128_CBC_SHA256 
REM MQ 9.1.2.0:  SSLCIPH = ANY_TLS12
IF (%MQVER%) GEQ (9120) ( set SSLCIPH=ANY_TLS12) ELSE ( set SSLCIPH=ECDHE_RSA_AES_128_CBC_SHA256)
echo Cipher spec used will be SSLCIPH=%SSLCIPH% (MQ Version is %MQVER%)

IF EXIST %CERTLOC% (
GOTO CONT:
) ELSE (
echo !! Directory %CERTLOC% Does not exists !!
echo !! Please check CERTLOC variable !!
echo --- Procedure end ---
GOTO END:
)

:CONT
IF EXIST %MQCHLLIBLOC% (
GOTO OK:
) ELSE (
echo !! Directory  %MQCHLLIBLOC% Does not exists !!
echo !! Please check MQCHLLIBLOC variable !!
echo --- Procedure end ---
GOTO END:
)

:OK
echo ------------------------------------------------------------------------------
echo --- Create new key DB + create and extract self signed certificate -----------
echo ------------------------------------------------------------------------------
echo ... Create %CERTLOC%\%MYCLIENT%.kdb key database
runmqakm -keydb -create -db %CERTLOC%\%MYCLIENT%.kdb -pw mqpass -stash -f
echo ... Create self signed certificate in %MYCLIENT%.kdb
runmqakm -cert -create -db %CERTLOC%\%MYCLIENT%.kdb -label %MYCLIENT%cert -pw mqpass -dn "CN=IBM, OU=Mylab, O=IBM, C=DE" -size 1024 -x509version 3 -expire 365 -sig_alg SHA1WithRSA
echo ... Extract self signed certificate %MYCLIENT%cert.arm 
REM Per "https://www.ibm.com/support/pages/specifying-userid-ssl-certificate-label-mq-client
REM The client label should be "ibmwebspheremq<user>". 
REM But "https://www.ibm.com/support/knowledgecenter/SSFKSJ_9.1.0/com.ibm.mq.sec.doc/q014340_.htm" 
REM Says it should also work by using user defiend label names
runmqakm -cert -extract -db %CERTLOC%\%MYCLIENT%.kdb -pw mqpass -label %MYCLIENT%cert -target %CERTLOC%\%MYCLIENT%cert.arm -format ascii -fips -f
dir /B %CERTLOC%\%MYCLIENT%*
echo ...
echo ... %QMGR1% Create key DB + create and extract self signed certificate 
echo ... %QMGR1% Create %CERTLOC%\%QMGR1%.kdb key database 
runmqakm -keydb -create -db %CERTLOC%\%QMGR1%.kdb -pw mqpass -stash -f
echo ... %QMGR1% Create self signed certificate in %QMGR1%.kdb
runmqakm -cert -create -db %CERTLOC%\%QMGR1%.kdb -label %QMGR1%cert -pw mqpass -dn "CN=IBM, OU=Mylab, O=IBM, C=DE" -size 1024 -x509version 3 -expire 365 -sig_alg SHA1WithRSA
echo ... %QMGR1% Extract self signed certificate %CERTLOC%\%QMGR1%cert.arm
runmqakm -cert -extract -db %CERTLOC%\%QMGR1%.kdb -pw mqpass -label %QMGR1%cert -target %CERTLOC%\%QMGR1%cert.arm -format ascii -fips -f
dir /B %CERTLOC%\%QMGR1%*
echo ...
echo ... %QMGR2% Create key DB + create and extract self signed certificate 
echo ... %QMGR2% Create %CERTLOC%\%QMGR2%.kdb key database
runmqakm -keydb -create -db %CERTLOC%\%QMGR2%.kdb -pw mqpass -stash -f
echo ... %QMGR2% Create self signed certificate in %QMGR2%.kdb 
runmqakm -cert -create -db %CERTLOC%\%QMGR2%.kdb -label %QMGR2%cert -pw mqpass -dn "CN=IBM, OU=Mylab, O=IBM, C=DE" -size 1024 -x509version 3 -expire 365 -sig_alg SHA1WithRSA
echo ... %QMGR2% Extract self signed certificate %CERTLOC%\%QMGR2%cert.arm
runmqakm -cert -extract -db %CERTLOC%\%QMGR2%.kdb -pw mqpass -label %QMGR2%cert -target %CERTLOC%\%QMGR2%cert.arm -format ascii -fips -f
dir /B %CERTLOC%\%QMGR2%*
echo ...
echo ... Add %MYCLIENT%.arm certificate to [%QMGR1%,%QMGR1%].kdb
runmqckm -cert -add -db %CERTLOC%\%QMGR1%.kdb -pw mqpass -label %MYCLIENT%cert -file %CERTLOC%\%MYCLIENT%cert.arm -format ascii 
runmqckm -cert -add -db %CERTLOC%\%QMGR2%.kdb -pw mqpass -label %MYCLIENT%cert -file %CERTLOC%\%MYCLIENT%cert.arm -format ascii 
echo ... Add [%QMGR1%,%QMGR1%].arm certificates to %MYCLIENT%.kdb
runmqckm -cert -add -db %CERTLOC%\%MYCLIENT%.kdb -pw mqpass -label %QMGR1%cert -file %CERTLOC%\%QMGR1%cert.arm -format ascii
runmqckm -cert -add -db %CERTLOC%\%MYCLIENT%.kdb -pw mqpass -label %QMGR2%cert -file %CERTLOC%\%QMGR2%cert.arm -format ascii
echo ... Add qmgr's certificates to [%QMGR1%,%QMGR1%].kdb
runmqckm -cert -add -db %CERTLOC%\%QMGR1%.kdb -pw mqpass -label %QMGR2%cert -file %CERTLOC%\%QMGR2%cert.arm -format ascii
runmqckm -cert -add -db %CERTLOC%\%QMGR2%.kdb -pw mqpass -label %QMGR1%cert -file %CERTLOC%\%QMGR1%cert.arm -format ascii
echo ...
echo ------------------------------------------------------------------------------
echo --- %QMGR1% specific MQ settings ---------------------------------------------
echo ------------------------------------------------------------------------------
Set QMGR=%QMGR1%
echo QMGR=%QMGR% and TCP listener port %QMGR1PORT%

echo ... End, remove (if existing) or create a new queuemanager %QMGR1% and start it
endmqm -i %QMGR%
dltmqm %QMGR%
echo ... Create a new queuemanager %QMGR1% (crtmqm -u %QMGR%.DLQ  %QMGR%) and start it
crtmqm -u %QMGR%.DLQ  %QMGR%
strmqm %QMGR%

echo ...
echo ... Create qmgr's %QMGR1% objects
echo ALTER QMGR CERTLABL('%QMGR1%cert') DEADQ('DLQ') SSLCRYP(' ') SSLKEYR('%CERTLOC%\%QMGR1%') FORCE > %QMGR%_temp.mcsc
echo DEFINE LISTENER(%QMGR%.LISTENER) TRPTYPE(TCP) PORT(%QMGR1PORT%) CONTROL(QMGR) >> %QMGR%_temp.mcsc
echo START LISTENER(%QMGR%.LISTENER) >> %QMGR%_temp.mcsc
echo DEFINE CHANNEL('CLIENT.TLS') CHLTYPE(CLNTCONN) CERTLABL('%MYCLIENT%cert') + >> %QMGR%_temp.mcsc
echo    CONNAME('localhost(%QMGR1PORT%)') QMNAME('%QMGR%')  SSLCIPH('%SSLCIPH%') TRPTYPE(TCP)  REPLACE >> %QMGR%_temp.mcsc
echo DEFINE CHL('CLIENT.TLS') CHLTYPE(SVRCONN) SSLCIPH('%SSLCIPH%') TRPTYPE(TCP) REPLACE >> %QMGR%_temp.mcsc
echo DEFINE QLOCAL(DLQ) REPLACE >> %QMGR%_temp.mcsc
echo DEFINE QLOCAL(QL1) REPLACE >> %QMGR%_temp.mcsc
echo DEFINE QLOCAL(%QMGR2%.XMIT) USAGE(XMITQ) TRIGGER INITQ('SYSTEM.CHANNEL.INITQ') REPLACE >> %QMGR%_temp.mcsc
echo DEFINE CHANNEL('%QMGR1%.TLS.%QMGR2%') CHLTYPE(SDR) CONNAME('localhost(%QMGR2PORT%)') SSLCIPH('%SSLCIPH%') TRPTYPE(TCP) XMITQ('%QMGR2%.XMIT') REPLACE >> %QMGR%_temp.mcsc
echo DEFINE CHANNEL('%QMGR2%.TLS.%QMGR1%') CHLTYPE(RCVR) SSLCIPH('%SSLCIPH%') TRPTYPE(TCP) REPLACE >> %QMGR%_temp.mcsc
echo DEFINE QREMOTE(QR2) RQMNAME('%QMGR2%') RNAME('QL2') XMITQ('%QMGR2%.XMIT') REPLACE >> %QMGR%_temp.mcsc
echo END >> %QMGR%_temp.mcsc
echo ... IBM MQ queue manager %QMGR% input mcsc file created:
echo .  
type %QMGR%_temp.mcsc

echo .
runmqsc -e %QMGR% < %QMGR%_temp.mcsc

echo ...
echo ... IBM MQ queue manager setmqaut execution
REM Set object authorities so user %USER is allowed to access the qmgr and queue
setmqaut -m %QMGR1% -t qmgr -p "%USER%" +connect 
setmqaut -m %QMGR1% -n "QL1" -t q -p "%USER%" +browse +get +inq +put +set
setmqaut -m %QMGR1% -n "QR2" -t q -p "%USER%" +browse +get +inq +put +set

echo ...
echo ------------------------------------------------------------------------------
echo --- %QMGR2% specific MQ settings ---------------------------------------------
echo ------------------------------------------------------------------------------
Set QMGR=%QMGR2%
echo QMGR=%QMGR% and TCP listener port %QMGR2PORT%

echo ... End, remove (if existing) or create a new queuemanger %QMGR1% and start it
endmqm -i %QMGR%
dltmqm %QMGR%
crtmqm -u %QMGR%.DLQ  %QMGR%
strmqm %QMGR%

echo ... Create qmgr's %QMGR2% objects
echo ALTER QMGR CERTLABL('%QMGR2%cert') DEADQ('DLQ') SSLCRYP(' ') SSLKEYR('%CERTLOC%\%QMGR2%') FORCE > %QMGR%_temp.mcsc
echo DEFINE LISTENER(%QMGR%.LISTENER) TRPTYPE(TCP) PORT(%QMGR2PORT%) CONTROL(QMGR) >> %QMGR%_temp.mcsc
echo START LISTENER(%QMGR%.LISTENER) >> %QMGR%_temp.mcsc
echo DEFINE QLOCAL(DLQ) REPLACE >> %QMGR%_temp.mcsc
echo DEFINE QLOCAL(QL2) REPLACE >> %QMGR%_temp.mcsc
echo DEFINE QLOCAL(%QMGR1%.XMIT) USAGE(XMITQ) TRIGGER INITQ('SYSTEM.CHANNEL.INITQ') REPLACE >> %QMGR%_temp.mcsc
echo DEFINE CHANNEL('%QMGR2%.TLS.%QMGR1%') CHLTYPE(SDR) CONNAME('localhost(%QMGR1PORT%)') SSLCIPH('%SSLCIPH%') TRPTYPE(TCP) XMITQ('%QMGR1%.XMIT') REPLACE >> %QMGR%_temp.mcsc
echo DEFINE CHANNEL('%QMGR1%.TLS.%QMGR2%') CHLTYPE(RCVR) SSLCIPH('%SSLCIPH%') TRPTYPE(TCP) REPLACE >> %QMGR%_temp.mcsc
echo DEFINE QREMOTE(QR1) RQMNAME('%QMGR1%') RNAME('QL1') XMITQ('%QMGR1%.XMIT') REPLACE >> %QMGR%_temp.mcsc
echo END >> %QMGR%_temp.mcsc
echo ... IBM MQ queue manager %QMGR% input mcsc file created:
echo .  
type %QMGR%_temp.mcsc
echo . 
runmqsc -e %QMGR% < %QMGR%_temp.mcsc
echo ... 

echo ...IBM MQ queue manager setmqaut execution
REM Set object authorities so user %USER% is allowed to access the qmgr and queue
setmqaut -m %QMGR2% -t qmgr -p "%USER%" +connect 
setmqaut -m %QMGR2% -n "QL2" -t q -p "%USER%" +browse +get +inq +put +set
setmqaut -m %QMGR2% -n "QR1" -t q -p "%USER%" +browse +get +inq +put +set

echo ------------------------------------------------------------------------------
echo --- Set Windows file permisssions on folder %CERTLOC% content ----------------
echo --- Because it was required on my Windows 10 box              ----------------
echo ... icacls %CERTLOC%\* /grant Administrator:(F)
icacls %CERTLOC%\* /grant Administrator:(F)
echo ... icacls %CERTLOC%\* /grant SYSTEM:(F)
icacls %CERTLOC%\* /grant SYSTEM:(F)
REM icacls %CERTLOC%\* /grant USERS:(F)
echo ------------------------------------------------------------------------------
dspmq -m %QMGR1%
dspmq -m %QMGR2%
echo ------------------------------------------------------------------------------
echo - You can now set env vars for samples utilities (as amqsputc, amqsgetc,...) 
echo - as requiered for you. Or use MQ explorer to test this secure MQ setup. 
echo - NOTE: Client SSL connect is configured for %QMGR1% only.
echo - For example: 
echo set MQSAMP_USER_ID=%USER%
echo set MQSSLKEYR=%CERTLOC%\%MYCLIENT%
echo set MQCHLLIB=%MQCHLLIBLOC%\%QMGR1%\@ipcc
echo set MQCHLTAB=AMQCLCHL.TAB
echo Start "amqsputc QL1 %QMGR1%" for test and set the correct password (write to local queue)
echo Start "amqsputc QR2 %QMGR1%" for test and set the correct password (write to remote queue)
echo Start "echo client test message to local | amqsput QL1 %QMGR1%" (unset MQSAMP_USER_ID, it does not work for amqsputc)
echo Below command works also for amqsputc but you need to set the password in the first line of the file
echo Start "amqsput QL1 %QMGR1% < mymessages.txt | "  (file mymessages.txt must exist and unset MQSAMP_USER_ID)
echo ------------------------------------------------------------------------------
echo --- Procedure end ---
:END
