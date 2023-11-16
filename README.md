# Simple-MQ-TLS-Setup
Sample of a secure Client-QMGR and QMGR-QMGR connection

Contact: niewolik@de.ibm.com


Overview
--------

**NOTE:** Only the Windows script (batch file) was tested but the Shell script should work as well. Files provided:
-    **CreateKeyDB_SelfSignedCerts.mkv** (demo how to use ikeyman tool to create key DB and certs, it's done by cmd **_runmqakm_** within the scripts). Please be aware when using MQ Version < V9, you may need to follow the label rules as described here: https://www.ibm.com/support/pages/specifying-userid-ssl-certificate-label-mq-client. Vor V9.1 I followed the recommendation described https://www.ibm.com/support/knowledgecenter/SSFKSJ_9.1.0/com.ibm.mq.sec.doc/q014340_.htm
-    **AddCertsToKeyDBs.mkv** (demo how to use ikeyman tool to add the selfsigned certs to the key DBs, it's done by cmd **_runmqckm_** within the scripts).)
-    **CreateMQSecEnv.bat** (create sample environment on Windows) 
-    **CreateMQSecEnv.sh** (create sample environment on Linux/UNIX; **not** tested yet) 

Both scripts are very simple **without** any error handling. The procedures have to be used on a host where both QMGRs are running locally,  otherwise you need to modify it. 

**Also "_Destinguish Name_" and "_Label Name_" check is not configured but you can easily test it by modifying the given channel definitions as  shown below.** 
- The Destinguish Name created by this procedure is _CN=IBM, OU=Mylab, O=IBM_  (during _runmqakm -cert -create ..._). If you have modified it, please change accordingly in the commands below. 
- In case you use diferent QMGR names, also change the _runmqsc_ command execution and channel name settings.
- The Label Names created follow that rules: _[QMGRNAME]cert_ and [MYCLIENT variable]cert. If you modified it, please change accordingly. 

**Destinguish Name check:**

    runmqsc  QM1SEC 
    ALTER CHANNEL('QM2SEC.TLS.QM1SEC') CHLTYPE(RCVR) SSLPEER('CN=IBM, OU=Mylab, O=IBM')
    ALTER CHANNEL('QM1SEC.TLS.QM2SEC') CHLTYPE(SDR) SSLPEER('CN=IBM, OU=Mylab, O=IBM')

    runmqsc  QM2SEC 
    ALTER CHANNEL('QM1SEC.TLS.QM2SEC') CHLTYPE(RCVR) SSLPEER('CN=IBM, OU=Mylab, O=IBM')
    ALTER CHANNEL('QM2SEC.TLS.QM1SEC') CHLTYPE(SDR) SSLPEER('CN=IBM, OU=Mylab, O=IBM')

For CLIENT (only configured to connect to QM1SEC so far):
    
    runmqsc  QM1SEC 
    ALTER CHANNEL('CLIENT.TLS') CHLTYPE(CLNTCONN) SSLPEER('CN=IBM, OU=Mylab, O=IBM')
    ALTER CHANNEL('CLIENT.TLS') CHLTYPE(SVRCONN) SSLPEER('CN=IBM, OU=Mylab, O=IBM')

**Label Name check:**
    
    runmqsc QM1SEC
    ALTER CHANNEL('QM2SEC.TLS.QM1SEC') CHLTYPE(RCVR) CERTLABL('QM1SECcert')
    ALTER CHANNEL('QM1SEC.TLS.QM2SEC') CHLTYPE(SDR) CERTLABL('QM1SECcert')

    runmqsc QM2SEC
    ALTER CHANNEL('QM1SEC.TLS.QM2SEC') CHLTYPE(RCVR)  CERTLABL('QM2SECcert')
    ALTER CHANNEL('QM2SEC.TLS.QM1SEC') CHLTYPE(SDR)  CERTLABL('QM2SECcert')

Kindly note that this script will set SSLCIPH to:
- **ECDHE_RSA_AES_128_CBC_SHA256**  for MQ Versions lower then 9.1.2.0
- **ANY_TLS12** for MQ Versions greater then or equal 9.1.2.0
You may adjust it if you use any MQ version which does not support above settings

Following configuration is set up with the script default values as provided (sample for Windows):

![Overview](https://media.github.ibm.com/user/85313/files/eb918d80-a01a-11ea-8322-6c0edded5f1f)


Usage
-----
-    You should first have a MQ 9.1 version installed. 
-    The user you set in the variable USER **must exist** otherwise setup will not work and _amqsputc_ will fail.
-    Upload the scripts by cloning the repository or cut and paste the code for _CreateMQSecEnv.bat_ and _CreateMQSecEnv.sh_ 
-    Modify the variables with the correct values and make sure that the directories you reference exists
     
         QMGR1=QM1SEC
         QMGR2=QM2SEC
         QMGR1PORT=9005
         QMGR2PORT=9006
         # It should be the USER used by your client
         USER=app
         # This variable is used to name the client key DB, cert label and cert file
         MYCLIENT=MyClient
         # Location where certificates will be be stored (also set at QMGR level)
         CERTLOC=C:\Certificates
         # Location MQCHLLIB folder
         MQCHLLIBLOC=C:\ProgramData\IBM\MQ\qmgrs

WINDOWS:
- Open CMD prompt with the appropriate MQ permissions (e.g. Adminstrator) and execute:

      C:> CreateMQSecEnv.bat 
- Files created in the execution folder
  - _%QMGR1%_temp.mcsc_
  - _%QMGR2%_temp.mcsc_
    
UNIX/Linux:
- Open shell with the appropriate MQ permissions and execute 

      $ CreateMQSecEnv.sh
- Files created in the $TMP folder (default is "/tmp")
  - _$TMP/$QMGR1_temp.mcsc_
  - _$TMP/$QMGR2_temp.mcsc_
  
Hints
-----

1. If you encounter security related issues you can disable it to move forward:

       ALTER QMGR CHLAUTH(DISABLED)
       ALTER QMGR CONNAUTH(' ')
       REFRESH SECURITY(*)
2. Stash files ([keyDBname].sth]

    The key tools are creating that file with restricted access permissions. The procedures try to overcome that issue but in case MQ cannot read it, you would need to adjust the access rigths.

Sample Run
----------

```
C:\WINDOWS\system32>CreateMQSecEnv.bat
--- Procedure start ---
------------------------------------------------------------------------------
--- Create new key DB + create and extract self signed certificate -----------
------------------------------------------------------------------------------
... Create C:\MyCertificates\MyClient.kdb key database
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
... Create self signed certificate in MyClient.kdb
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
... Extract self signed certificate MyClientcert.arm
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
MyClient.crl
MyClient.kdb
MyClient.rdb
MyClient.sth
MyClientcert.arm
... QM1SEC Create key DB + create and extract self signed certificate
... QM1SEC Create C:\MyCertificates\QM1SEC.kdb key database
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
... QM1SEC Create self signed certificate in QM1SEC.kdb
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
... QM1SEC Extract self signed certificate C:\MyCertificates\QM1SECcert.arm
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
QM1SEC.crl
QM1SEC.kdb
QM1SEC.rdb
QM1SEC.sth
QM1SECcert.arm
... QM2SEC Create key DB + create and extract self signed certificate
... QM2SEC Create C:\MyCertificates\QM2SEC.kdb key database
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
... QM2SEC Create self signed certificate in QM2SEC.kdb
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
... QM2SEC Extract self signed certificate C:\MyCertificates\QM2SECcert.arm
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
QM2SEC.crl
QM2SEC.kdb
QM2SEC.rdb
QM2SEC.sth
QM2SECcert.arm
... Add MyClient.arm certificate to [QM1SEC,QM1SEC].kdb
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
... Add [QM1SEC,QM1SEC].arm certificates to MyClient.kdb
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
... Add qmgr's certificates to [QM1SEC,QM1SEC].kdb
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
------------------------------------------------------------------------------
--- QM1SEC specific MQ settings ---------------------------------------------
------------------------------------------------------------------------------
QMGR=QM1SEC and TCP listener port 9005
... End, remove (if existing) or create a new queuemanager QM1SEC and start it
IBM MQ queue manager 'QM1SEC' ending.
IBM MQ queue manager 'QM1SEC' ended.
IBM MQ queue manager 'QM1SEC' deleted.
... Create a new queuemanager QM1SEC (crtmqm -u QM1SEC.DLQ  QM1SEC) and start it
IBM MQ queue manager created.
Directory 'C:\ProgramData\IBM\MQ\qmgrs\QM1SEC' created.
The queue manager is associated with installation 'Installation1'.
Creating or replacing default objects for queue manager 'QM1SEC'.
Default objects statistics : 86 created. 0 replaced. 0 failed.
Completing setup.
Setup completed.
IBM MQ queue manager 'QM1SEC' starting.
The queue manager is associated with installation 'Installation1'.
5 log records accessed on queue manager 'QM1SEC' during the log replay phase.
Log replay for queue manager 'QM1SEC' complete.
Transaction manager state recovered for queue manager 'QM1SEC'.
IBM MQ queue manager 'QM1SEC' started using V9.1.3.0.
...
... Create qmgr's QM1SEC objects
... IBM MQ queue manager QM1SEC input mcsc file created:
.
ALTER QMGR CERTLABL('QM1SECcert') DEADQ('DLQ') SSLCRYP(' ') SSLKEYR('C:\MyCertificates\QM1SEC') FORCE
DEFINE LISTENER(QM1SEC.LISTENER) TRPTYPE(TCP) PORT(9005) CONTROL(QMGR)
START LISTENER(QM1SEC.LISTENER)
DEFINE CHANNEL('CLIENT.TLS') CHLTYPE(CLNTCONN) CERTLABL('MyClientcert') +
   CONNAME('localhost(9005)') QMNAME('QM1SEC')  SSLCIPH('ANY_TLS12') TRPTYPE(TCP)  REPLACE
DEFINE CHL('CLIENT.TLS') CHLTYPE(SVRCONN) SSLCIPH('ANY_TLS12') TRPTYPE(TCP) REPLACE
DEFINE QLOCAL(DLQ) REPLACE
DEFINE QLOCAL(QL1) REPLACE
DEFINE QLOCAL(QM2SEC.XMIT) USAGE(XMITQ) TRIGGER INITQ('SYSTEM.CHANNEL.INITQ') REPLACE
DEFINE CHANNEL('QM1SEC.TLS.QM2SEC') CHLTYPE(SDR) CONNAME('localhost(9006)') SSLCIPH('ANY_TLS12') TRPTYPE(TCP) XMITQ('QM2SEC.XMIT') REPLACE
DEFINE CHANNEL('QM2SEC.TLS.QM1SEC') CHLTYPE(RCVR) SSLCIPH('ANY_TLS12') TRPTYPE(TCP) REPLACE
DEFINE QREMOTE(QR2) RQMNAME('QM2SEC') RNAME('QL2') XMITQ('QM2SEC.XMIT') REPLACE
END
.
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
Starting MQSC for queue manager QM1SEC.

AMQ8005I: IBM MQ queue manager changed.
AMQ8626I: IBM MQ listener created.
AMQ8021I: Request to start IBM MQ listener accepted.
AMQ8014I: IBM MQ channel created.
AMQ8014I: IBM MQ channel created.
AMQ8006I: IBM MQ queue created.
AMQ8006I: IBM MQ queue created.
AMQ8006I: IBM MQ queue created.
AMQ8014I: IBM MQ channel created.
AMQ8014I: IBM MQ channel created.
AMQ8006I: IBM MQ queue created.
11 MQSC commands read.
No commands have a syntax error.
All valid MQSC commands were processed.
... IBM MQ queue manager setmqaut execution
The setmqaut command completed successfully.
The setmqaut command completed successfully.
The setmqaut command completed successfully.
------------------------------------------------------------------------------
--- QM2SEC specific MQ settings ---------------------------------------------
------------------------------------------------------------------------------
QMGR=QM2SEC and TCP listener port 9006
... End, remove (if existing) or create a new queuemanger QM1SEC and start it
IBM MQ queue manager 'QM2SEC' ending.
IBM MQ queue manager 'QM2SEC' ended.
IBM MQ queue manager 'QM2SEC' deleted.
IBM MQ queue manager created.
Directory 'C:\ProgramData\IBM\MQ\qmgrs\QM2SEC' created.
The queue manager is associated with installation 'Installation1'.
Creating or replacing default objects for queue manager 'QM2SEC'.
Default objects statistics : 86 created. 0 replaced. 0 failed.
Completing setup.
Setup completed.
IBM MQ queue manager 'QM2SEC' starting.
The queue manager is associated with installation 'Installation1'.
5 log records accessed on queue manager 'QM2SEC' during the log replay phase.
Log replay for queue manager 'QM2SEC' complete.
Transaction manager state recovered for queue manager 'QM2SEC'.
IBM MQ queue manager 'QM2SEC' started using V9.1.3.0.
... Create qmgr's QM2SEC objects
... IBM MQ queue manager QM2SEC input mcsc file created:
.
ALTER QMGR CERTLABL('QM2SECcert') DEADQ('DLQ') SSLCRYP(' ') SSLKEYR('C:\MyCertificates\QM2SEC') FORCE
DEFINE LISTENER(QM2SEC.LISTENER) TRPTYPE(TCP) PORT(9006) CONTROL(QMGR)
START LISTENER(QM2SEC.LISTENER)
DEFINE QLOCAL(DLQ) REPLACE
DEFINE QLOCAL(QL2) REPLACE
DEFINE QLOCAL(QM1SEC.XMIT) USAGE(XMITQ) TRIGGER INITQ('SYSTEM.CHANNEL.INITQ') REPLACE
DEFINE CHANNEL('QM2SEC.TLS.QM1SEC') CHLTYPE(SDR) CONNAME('localhost(9005)') SSLCIPH('ANY_TLS12') TRPTYPE(TCP) XMITQ('QM1SEC.XMIT') REPLACE
DEFINE CHANNEL('QM1SEC.TLS.QM2SEC') CHLTYPE(RCVR) SSLCIPH('ANY_TLS12') TRPTYPE(TCP) REPLACE
DEFINE QREMOTE(QR1) RQMNAME('QM1SEC') RNAME('QL1') XMITQ('QM1SEC.XMIT') REPLACE
.
5724-H72 (C) Copyright IBM Corp. 1994, 2019.
Starting MQSC for queue manager QM2SEC.

AMQ8005I: IBM MQ queue manager changed.
AMQ8626I: IBM MQ listener created.
AMQ8021I: Request to start IBM MQ listener accepted.
AMQ8006I: IBM MQ queue created.
AMQ8006I: IBM MQ queue created.
AMQ8006I: IBM MQ queue created.
AMQ8014I: IBM MQ channel created.
AMQ8014I: IBM MQ channel created.
AMQ8006I: IBM MQ queue created.
9 MQSC commands read.
No commands have a syntax error.
All valid MQSC commands were processed.
...
...IBM MQ queue manager setmqaut execution
The setmqaut command completed successfully.
The setmqaut command completed successfully.
The setmqaut command completed successfully.
------------------------------------------------------------------------------
--- Set Windows file permisssions on folder C:\MyCertificates content ----------------
--- Because it was required on my Windows 10 box              ----------------
... icacls C:\MyCertificates\* /grant Administrator:(F)
Successfully processed 15 files; Failed processing 0 files
... icacls C:\MyCertificates\* /grant SYSTEM:(F)
Successfully processed 15 files; Failed processing 0 files
------------------------------------------------------------------------------
QMNAME(QM1SEC)                                            STATUS(Running)
QMNAME(QM2SEC)                                            STATUS(Running)
------------------------------------------------------------------------------
- You can now set env vars for samples utilities (as amqsputc, amqsgetc,...)
- as requiered for you. Or use MQ explorer to test this secure MQ setup.
- NOTE: Client SSL connect is configured for QM1SEC only.
- For example:
set MQSAMP_USER_ID=app
set MQSSLKEYR=C:\MyCertificates\MyClient
set MQCHLLIB=C:\ProgramData\IBM\MQ\qmgrs\QM1SEC\@ipcc
set MQCHLTAB=AMQCLCHL.TAB
Start "amqsputc QL1 QM1SEC" for test and set the correct password (write to local queue)
Start "amqsputc QR2 QM1SEC" for test and set the correct password (write to remote queue)
------------------------------------------------------------------------------
--- Procedure end ---
C:\WINDOWS\system32>
```
