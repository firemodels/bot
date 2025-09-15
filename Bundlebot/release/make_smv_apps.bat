@echo off
set error=0

set CURDIR=%CD%

git clean -dxf  1>> Nul 2>&1

set clean_log=%CURDIR%\output\clean.log
set compile_log=%CURDIR%\output\compile.log
set error_log=%CURDIR%\output\error.log

echo. > %clean_log%
echo. > %compile_log%
echo. > %error_log%

cd ..\..\..
set REPOROOT=%CD%

cd %REPOROOT%\smv\
set smvrepo=%CD%

cd %REPOROOT%\bot
set botrepo=%CD%

cd %smvrepo%\Source
echo ***cleaning %smvrepo%\Source
git clean -dxf  1>> %clean_log% 2>&1

cd %smvrepo%\Build
echo ***cleaning %smvrepo%\Build
git clean -dxf  1>> %clean_log% 2>&1

:: setup compiler
cd %CURDIR%
call %smvrepo%\Utilities\Scripts\setup_intel_compilers.bat 1>> %compile_log% 2>&1
timeout /t 30 > Nul

:: build smokeview libraries and apps
call :BUILDLIB
call :BUILD     background
call :BUILD     fds2fed
call :BUILD     flush
call :BUILD     get_time
call :BUILD     hashfile
call :BUILD     set_path
call :BUILD     sh2bat
call :BUILD     pnginfo
call :BUILD     smokediff
call :BUILD     smokezip
call :BUILD     timep
call :BUILD     wind2fds
call :BUILDSMV

:: verify smokeview apps were built
call :CHECK_BUILD     background
call :CHECK_BUILD     fds2fed
call :CHECK_BUILD     flush
call :CHECK_BUILD     get_time
call :CHECK_BUILD     hashfile
call :CHECK_BUILD     set_path
call :CHECK_BUILD     sh2bat
call :CHECK_BUILD     pnginfo
call :CHECK_BUILD     smokediff
call :CHECK_BUILD     smokezip
call :CHECK_BUILD     timep
call :CHECK_BUILD     wind2fds
call :CHECK_BUILDSMV

echo.
echo ***build complete
echo.

cd %CURDIR%

goto eof

:: -------------------------------------------------------------
 :BUILDUTIL
:: -------------------------------------------------------------

set prog=%1
set builddir=%2

echo ***building %prog%
echo.                1>> %compile_log% 2>&1
echo *************** 1>> %compile_log% 2>&1
echo ***building %prog% 1>> %compile_log% 2>&1
cd %fdsrepo%\Utilities\%prog%\%builddir%
call make_%prog% bot 1>> %compile_log% 2>&1
exit /b /0

:: -------------------------------------------------------------
 :CHECK_BUILDUTIL
:: -------------------------------------------------------------

set prog=%1
set builddir=%2
set suffix=%3

if NOT exist %fdsrepo%\Utilities\%prog%\%builddir%\%prog%%suffix%.exe goto check_util
exit /b /0
:check_util
echo ***error: The program %prog%%suffix%.exe failed to build
echo ***error: The program %prog%%suffix%.exe failed to build  1>> %error_log% 2>&1
set error=1
exit /b /1

:: -------------------------------------------------------------
 :BUILDLIB
:: -------------------------------------------------------------

echo ***building smokeview libraries
echo.                1>> %compile_log% 2>&1
echo *************** 1>> %compile_log% 2>&1
echo ***building smokeview libraries 1>> %compile_log% 2>&1

cd %smvrepo%\Build\LIBS\intel_win_64
call make_LIBS_bot 1>> %compile_log% 2>&1
exit /b /0

:: -------------------------------------------------------------
 :BUILDSMV
:: -------------------------------------------------------------

echo ***building smokeview
echo.                1>> %compile_log% 2>&1
echo *************** 1>> %compile_log% 2>&1
echo ***building smokeview  1>> %compile_log% 2>&1
cd %smvrepo%\Build\smokeview\intel_win_64
call make_smokeview -release -bot 1>> %compile_log% 2>&1
exit /b /0

:: -------------------------------------------------------------
 :CHECK_BUILDSMV
:: -------------------------------------------------------------

if NOT exist %smvrepo%\Build\smokeview\intel_win_64\smokeview_win_64.exe goto not_smokeview
exit /b /0
:not_smokeview
echo ***error: The program smokeview_win_64.exe failed to build
echo ***error: The program smokeview_win_64.exe failed to build  1>> %error_log% 2>&1
set error=1
exit /b /1

:: -------------------------------------------------------------
 :BUILD
:: -------------------------------------------------------------

set prog=%1
set script=make_%prog%

echo ***building %prog%
echo.                1>> %compile_log% 2>&1
echo *************** 1>> %compile_log% 2>&1
echo ***building %prog% 1>> %compile_log% 2>&1
cd %smvrepo%\Build\%prog%\intel_win_64
call %script% bot 1>> %compile_log% 2>&1
exit /b /0

:: -------------------------------------------------------------
 :CHECK_BUILD
:: -------------------------------------------------------------

set prog=%1

if NOT exist %smvrepo%\Build\%prog%\intel_win_64\%prog%_win_64.exe goto notexist
exit /b /0
:notexist
echo ***error: The program %prog%_win_64.exe failed to build
echo ***error: The program %prog%_win_64.exe failed to build  1>> %error_log% 2>&1
set error=1
exit /b /1

:eof

if "%error%" == "0" exit /b 0
exit /b 1
