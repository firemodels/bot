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

cd %REPOROOT%\fds
set fdsrepo=%CD%

cd %REPOROOT%\bot
set botrepo=%CD%

cd %smvrepo%\Source
echo ***cleaning %smvrepo%\Source
git clean -dxf  1>> %clean_log% 2>&1

cd %smvrepo%\Build
echo ***cleaning %smvrepo%\Build
git clean -dxf  1>> %clean_log% 2>&1

cd %fdsrepo%\Build
echo ***cleaning %fdsrepo%\Build
git clean -dxf  1>> %clean_log% 2>&1

cd %fdsrepo%\Utilities
echo ***cleaning %fdsrepo%\Utilities
echo.
git clean -dxf  1>> %clean_log% 2>&1

:: setup compiler
cd %CURDIR%
call %smvrepo%\Utilities\Scripts\setup_intel_compilers.bat 1>> %compile_log% 2>&1
timeout /t 30 > Nul

:: build fds apps
call :BUILDUTIL fds2ascii intel_win
call :BUILDUTIL test_mpi  impi_intel_win
call :BUILDFDS

:: build smokeview libraries and apps
call :BUILDLIB
call :BUILD     background
call :BUILD     hashfile
call :BUILD     smokediff
call :BUILD     pnginfo
call :BUILD     fds2fed
call :BUILD     smokezip
call :BUILD     wind2fds
call :BUILD     set_path
call :BUILD     sh2bat
call :BUILD     get_time
call :BUILDSMV

:: verify fds apps were built
call :CHECK_BUILDUTIL    fds2ascii intel_win
call :CHECK_BUILDTESTMPI  
call :CHECK_BUILDFDS
call :CHECK_BUILDFDSOPENMP

:: verify smokeview apps were built
call :CHECK_BUILD     background
call :CHECK_BUILD     hashfile
call :CHECK_BUILD     smokediff
call :CHECK_BUILD     pnginfo
call :CHECK_BUILD     fds2fed
call :CHECK_BUILD     smokezip
call :CHECK_BUILD     wind2fds
call :CHECK_BUILD     set_path
call :CHECK_BUILD     sh2bat
call :CHECK_BUILD     get_time
call :CHECK_BUILDSMV

echo.
echo ***build complete
echo.

cd %CURDIR%

goto eof

:: -------------------------------------------------------------
 :BUILDFDS
:: -------------------------------------------------------------

echo ***building fds
echo.                1>> %compile_log% 2>&1
echo *************** 1>> %compile_log% 2>&1

echo ***building fds 1>> %compile_log% 2>&1
cd %fdsrepo%\Build\impi_intel_win
call make_fds bot 1>> %compile_log% 2>&1

echo ***building fds openmp
echo ***building fds openmp 1>> %compile_log% 2>&1
cd %fdsrepo%\Build\impi_intel_win_openmp
call make_fds bot 1>> %compile_log% 2>&1
exit /b /0

:: -------------------------------------------------------------
 :CHECK_BUILDFDS
:: -------------------------------------------------------------

if NOT exist %fdsrepo%\Build\impi_intel_win\fds_impi_intel_win.exe goto check_fds
exit /b /0
:check_fds
echo ***error: The program fds_impi_win.exe failed to build
echo ***error: The program fds_impi_win.exe failed to build  1>> %error_log% 2>&1
exit /b /1

:: -------------------------------------------------------------
 :CHECK_BUILDFDSOPENMP
:: -------------------------------------------------------------

if NOT exist %fdsrepo%\Build\impi_intel_win_openmp\fds_impi_intel_win_openmp.exe goto check_fds
exit /b /0
:check_fds
echo ***error: The program fds_impi_win_openmp.exe failed to build
echo ***error: The program fds_impi_win_openmp.exe failed to build  1>> %error_log% 2>&1
exit /b /1

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
 :CHECK_BUILDTESTMPI
:: -------------------------------------------------------------


if NOT exist %fdsrepo%\Utilities\test_mpi\impi_intel_win\test_mpi.exe goto check_util
exit /b /0
:check_util
echo ***error: The program test_mpi.exe failed to build
echo ***error: The program test_mpi.exe failed to build  1>> %error_log% 2>&1
set error=1
exit /b /1

:: -------------------------------------------------------------
 :CHECK_BUILDUTIL
:: -------------------------------------------------------------

set prog=%1
set builddir=%2
set suffix=%3

if NOT exist %fdsrepo%\Utilities\%prog%\%builddir%\%prog%_%builddir%.exe goto check_util
exit /b /0
:check_util
echo ***error: The program %prog%_%builddir%.exe failed to build
echo ***error: The program %prog%_%builddir%.exe failed to build  1>> %error_log% 2>&1
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
