@echo off

::-----------------------------------------------------------------------
::start of script
::-----------------------------------------------------------------------

call :getopts %*

set CURDIR=%CD%
cd ..\..\Scripts
set EMAIL=%CD%\email_insert.bat
cd %CURDIR%

set INFO=FDS_INFO.txt
if exist %INFO% erase %INFO%
if exist FDS_REVISION.txt erase FDS_REVISION.txt
if exist SMV_REVISION.txt erase SMV_REVISION.txt

gh release download FDS_TEST -p %INFO% -D .  -R github.com/firemodels/test_bundles
grep FDS_REVISION %INFO% | gawk "{print $2}" > FDS_REVISION.txt
set /p FDS_REVISION=<FDS_REVISION.txt
grep SMV_REVISION %INFO% | gawk "{print $2}" > SMV_REVISION.txt
set /p SMV_REVISION=<SMV_REVISION.txt
set VIRUSLOG=output\%FDS_REVISION%_%SMV_REVISION%_nightly_win_vscan.log

set SCANSUMMARY=scansummary.log
if exist %SCANSUMMARY% erase %SCANSUMMARY%

call :SCANVIRUSLOG %VIRUSLOG%

::copy virus logs 

set VIRUSSTATUS="No Windows viruses found in %FDS_REVISION%_%SMV_REVISION%_nightly_win bundle"
if NOT %ninfected% == 0 set VIRUSSTATUS="***error: %ninfected% viruses found in %FDS_REVISION%_%SMV_REVISION%_nightly_win bundle"

call %EMAIL% %emailto% %VIRUSSTATUS% %SCANSUMMARY%

goto eof
::-----------------------------------------------------------------------
:usage
::-----------------------------------------------------------------------

  echo.
  echo CheckNightly usage
  echo.
  echo This script checks if nightly fds/smv bundles were generated
  echo.
  echo Options:
  echo -h - display this message
  echo -m mailtto - send email to mailto
  exit /b 0

::-----------------------------------------------------------------------
:SCANVIRUSLOG
::-----------------------------------------------------------------------
  set SCANLOGFILE=%1
  grep "Infected files" %SCANLOGFILE% | gawk -F: "{print $2}" > ninfected.txt
  set /p ninfected=<ninfected.txt
  if %ninfected% NEQ 0 echo "***error: %ninfected% infected files found in %SCANLOGFILE%" >> %SCANSUMMARY%
  grep -v OK$ %SCANLOGFILE%                                                               >> %SCANSUMMARY%
  exit /b 0

::-----------------------------------------------------------------------
:getopts
::-----------------------------------------------------------------------
  set stopscript=
  if (%1)==() exit /b
  set valid=0
  set arg=%1
 
  if "%1" EQU "-h" (
    call :usage
    set stopscript=1
    exit /b
  )
  if "%1" EQU "-m" (
    set emailto=%2
    set valid=1
    shift
  )
  shift
  if %valid% == 0 (
    echo.
    echo ***Error: the input argument %arg% is invalid
    echo.
    echo Usage:
    call :usage
    set stopscript=1
    exit /b 1
  )
  if not (%1)==() goto getopts
  exit /b 0

:eof