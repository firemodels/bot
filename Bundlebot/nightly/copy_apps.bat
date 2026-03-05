@echo off
setlocal
set error=0
set type=%1

set scriptdir=%~dp0
set curdir=%CD%
cd %scriptdir%\..\..\..
set GITROOT=%CD%
set fdsrepo=%GITROOT%\fds
set smvrepo=%GITROOT%\smv
cd %scriptdir%

set BUNDLE_DIR=%userprofile%\.bundle

:: copy smokeview files

if NOT exist %BUNDLE_DIR%\smv mkdir %BUNDLE_DIR%\smv

if "%type%" == "fds" goto skip_smokeview
echo.
echo ***erasing %BUNDLE_DIR%\smv
echo.
erase /q %BUNDLE_DIR%\smv\*
call :copyfile %smvrepo%\Build\background\intel_win background_win.exe %BUNDLE_DIR%\smv background.exe
call :copyfile %smvrepo%\Build\smokediff\intel_win  smokediff_win.exe  %BUNDLE_DIR%\smv smokediff.exe
call :copyfile %smvrepo%\Build\pnginfo\intel_win    pnginfo_win.exe    %BUNDLE_DIR%\smv pnginfo.exe
call :copyfile %smvrepo%\Build\fds2fed\intel_win    fds2fed_win.exe    %BUNDLE_DIR%\smv fds2fed.exe
call :copyfile %smvrepo%\Build\smokeview\intel_win  smokeview_win.exe  %BUNDLE_DIR%\smv smokeview.exe
call :copyfile %smvrepo%\Build\smokezip\intel_win   smokezip_win.exe   %BUNDLE_DIR%\smv smokezip.exe
call :copyfile %smvrepo%\Build\wind2fds\intel_win   wind2fds_win.exe   %BUNDLE_DIR%\smv wind2fds.exe
:skip_smokeview

:: copy fds files

if "%type%" == "smv" goto skip_fds
if NOT exist %BUNDLE_DIR%\fds mkdir %BUNDLE_DIR%\fds
echo.
echo ***erasing %BUNDLE_DIR%\fds
echo.
erase /q %BUNDLE_DIR%\fds\*
call :copyfile %fdsrepo%\Build\impi_intel_win              fds_impi_intel_win.exe          %BUNDLE_DIR%\fds fds.exe
call :copyfile %fdsrepo%\Build\impi_intel_win_openmp       fds_impi_intel_win_openmp.exe   %BUNDLE_DIR%\fds fds_openmp.exe
call :copyfile %fdsrepo%\Utilities\fds2ascii\intel_win     fds2ascii_intel_win.exe         %BUNDLE_DIR%\fds fds2ascii.exe
call :copyfile %fdsrepo%\Utilities\test_mpi\impi_intel_win test_mpi.exe                    %BUNDLE_DIR%\fds test_mpi.exe
:skip_fds

goto eof
  
::---------------------------------------------
  :copyfile
::---------------------------------------------

set FROMDIR=%1
set FROMFILE=%2
set TODIR=%3
set TOFILE=%4

if exist %FROMDIR%\%FROMFILE% goto else1
    echo "***error: %FROMFILE% was not found in %FROMDIR%"
    set error=1
:else1
    copy /Y %FROMDIR%\%FROMFILE% %TODIR%\%TOFILE% > Nul 2> Nul
    if NOT exist %TODIR%\%TOFILE% goto else2
      echo %FROMFILE% copied to %TODIR%\%TOFILE%
      goto endif1
:else2
      echo ***error: %FROMFILE% could not be copied to %TODIR%
      set error=1
:endif1
exit /b

:eof

if "%error%" == "0" exit /b 0
exit /b 1
