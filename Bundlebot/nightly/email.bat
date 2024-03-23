@echo off
set from=%1
set to=%2
head -1 %userprofile%\.firebot\userpass.txt > user.txt
tail -1 %userprofile%\.firebot\userpass.txt > pass.txt

set /p user=<user.txt
set /p pass=<pass.txt
erase user.txt pass.txt

mailsend1.19.exe -t %to% -f %from% -starttls -port 587  -smtp smtp.gmail.com -sub test -M test -auth-login -user %user% -password %pass%
