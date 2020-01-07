@echo off

set repo=
set stopscript=0
set verbose=0

call :getopts %*
if %stopscript% == 1 (
  exit /b
)

set mypath=%~dp0

if x%repo% == x goto else1
  set smokeview=%userprofile%\%repo%\smv\Build\smokeview\gnu_win_64\smokeview_win_test_64_db.exe
  if EXIST %smokeview% goto endif1
  echo ***error: %smokeview% does not exist
  echo aborted
  exit /b
:else1
  set smokeview=smokeview_gnu.exe
  call :is_file_installed %smokeview% || exit /b 1
  where %smokeview% | head -1 > %TEMP%\smokeview_path.txt
  set /p smv=<%TEMP%\smokeview_path.txt
  set "smokeview=%smv%"
:endif1

if "%option%" == "profile" goto else2
  if "%verbose%" == "1" echo "%smokeview%" %casename%
  if "%verbose%" == "0" "%smokeview%" %casename%
  goto eof
:else2
  call :is_file_installed gprof || exit /b 1
  if "%verbose%" == "1" echo gprof "%smokeview% >" %casename%_profile.txt
  if "%verbose%" == "0" gprof "%smokeview%" > %casename%_profile.txt
  if "%verbose%" == "0" echo profile information outputted to %casename%_profile.txt
:endif2
goto eof

:: -------------------------------------------------------------
:is_file_installed
:: -------------------------------------------------------------

  set program=%1
  set exist=%TEMP%\exist.txt
  set count=%TEMP%\count.txt
  %program% --help 1>> %exist% 2>&1
  type %exist% | find /i /c "not recognized" > %count%
  set /p nothave=<%count%
  if %nothave% == 1 (
    echo "***Fatal error: %program% not present"
    erase %exist%
    erase %count%
    exit /b 1
  )
  erase %exist%
  erase %count%
  exit /b 0

:: -------------------------------------------------------------
:getopts
:: -------------------------------------------------------------
 set stopscript=0
 if (%1)==() exit /b
 set valid=0
 set arg=%1
 set firstchar=%arg:~0,1%
 if NOT "%firstchar%" == "-" goto endloop
 if /I "%1" EQU "-h" (
   call :usage
   set stopscript=1
   exit /b
 )
 if /I "%1" EQU "-p" (
   set option=profile
   set valid=1
 )
 if /I "%1" EQU "-repo" (
   set repo=%2
   set valid=1
   shift
 )
 if /I "%1" EQU "-rep" (
   set repo=FireModels_fork
   set valid=1
 )
 if /I "%1" EQU "-run" (
   set option=run
   set valid=1
 )
 if /I "%1" EQU "-v" (
   set verbose=1
   set valid=1
 )
 shift
 if %valid% == 0 (
   echo.
   echo ***Error: the argument %arg% is invalid
   echo.
   echo Usage:
   call :usage
   set stopscript=1
   exit /b
 )
if not (%1)==() goto getopts
:endloop
set casename=%arg%
exit /b

:: -------------------------------------------------------------
:usage
:: -------------------------------------------------------------
echo profile [options] casename
echo. 
echo -h         - display this message
echo -p         - profile smokeview_gnu run [default]
echo -i         - use installed version of smokeview_gnu [default]
echo -repo repo - use repo version of smokeview_gnu, otherwise use installed version
echo -run       - run smokeview_gnu
echo -v         - show command used to run smokeview or profiler
exit /b

:eof