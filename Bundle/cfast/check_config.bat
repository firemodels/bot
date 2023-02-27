@echo off
setlocal
set error=0
call :check bundle_host            || set error=1
call :check bundle_smokebot_home   || set error=1
call :check bundle_firebot_home    || set error=1
call :check bundle_cfastbot_home   || set error=1
call :check bundle_root            || set error=1
call :check bundle_logon           || set error=1

goto eof

::-------------------------------
:check
::-------------------------------
set varptr=%1
if not defined %varptr% echo ***error: environment variable %varptr% is not defined
if not defined %varptr% exit /b 1
exit /b

:eof

if %error% == 1 exit /b 1
exit /b 0
