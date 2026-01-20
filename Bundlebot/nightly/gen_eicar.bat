echo off
set OUTPUT=%1
set TEST=%2
if x%OUTPUT% == x echo ***error: specify an output file
if x%OUTPUT% == x exit /b

:: if TEST is null then OUTPUT will contain the eicar test string
:: if TEST contains a string then it will not (ie will not be quarantined by a virus scanner)
<nul set /p=%TEST%X5O^!P%%@AP[4\PZX54^(P^^^)7CC^)7^}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE^!$H+H^*%TEST%>stdout