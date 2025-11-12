@echo off
set error=0
set SHASH=%1
set SREVISION=%2

if "x%SHASH%" == "x" goto else1
echo %SHASH%     > output\SMV_HASH
echo %SREVISION% > output\SMV_REVISION
goto eof
:else1
call :getfile SMV_INFO.txt
grep SMV_HASH     output\SMV_INFO.txt | gawk "{print $2}" > output\SMV_HASH
grep SMV_REVISION output\SMV_INFO.txt | gawk "{print $2}" > output\SMV_REVISION
goto eof

::-----------------------------------------------------------------------
:getfile
::-----------------------------------------------------------------------
set file=%1
if exist output\%file% erase output\%file%

echo downloading %file%
gh release download SMOKEVIEW_TEST -p %file% -R github.com/firemodels/test_bundles -D output --clobber
if NOT exist output\%file% echo failed
exit /b

:eof

if "%error%" == "1" exit /b 1
exit /b 0
