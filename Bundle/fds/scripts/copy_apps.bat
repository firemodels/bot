@echo off

set scriptdir=%~dp0
set curdir=%CD%
cd %scriptdir%\..\..\..\..
set repo_root=%CD%
set fdsrepo=%repo_root%\fds
set smvrepo=%repo_root%\smv
cd %scriptdir%

set BUNDLE_DIR=%userprofile%\.bundle

:: copy smokeview files

if NOT exist %BUNDLE_DIR%\smv mkdir %BUNDLE_DIR%\smv

echo erasing %BUNDLE_DIR%\smv
echo.
erase /q %BUNDLE_DIR%\smv\*
call :copyfile %smvrepo%\Build\background\intel_win_64 background.exe       %BUNDLE_DIR%\smv background.exe
call :copyfile %smvrepo%\Build\dem2fds\intel_win_64    dem2fds_win_64.exe   %BUNDLE_DIR%\smv dem2fds.exe
call :copyfile %smvrepo%\Build\hashfile\intel_win_64   hashfile_win_64.exe  %BUNDLE_DIR%\smv hashfile.exe
call :copyfile %smvrepo%\Build\smokediff\intel_win_64  smokediff_win_64.exe %BUNDLE_DIR%\smv smokediff.exe
call :copyfile %smvrepo%\Build\smokeview\intel_win_64  smokeview_win_64.exe %BUNDLE_DIR%\smv smokeview.exe
call :copyfile %smvrepo%\Build\smokezip\intel_win_64   smokezip_win_64.exe  %BUNDLE_DIR%\smv smokezip.exe
call :copyfile %smvrepo%\Build\wind2fds\intel_win_64   wind2fds_win_64.exe  %BUNDLE_DIR%\smv wind2fds.exe

:: copy fds files

if NOT exist %BUNDLE_DIR%\fds mkdir %BUNDLE_DIR%\fds
echo erasing %BUNDLE_DIR%\fds
echo.
erase /q %BUNDLE_DIR%\fds\*
call :copyfile %fdsrepo%\Build\impi_intel_win_64           fds_impi_win_64.exe  %BUNDLE_DIR%\fds fds.exe
call :copyfile %fdsrepo%\Utilities\fds2ascii\intel_win_64  fds2ascii_win_64.exe %BUNDLE_DIR%\fds fds2ascii.exe
call :copyfile %fdsrepo%\Utilities\test_mpi\impi_intel_win test_mpi.exe         %BUNDLE_DIR%\fds test_mpi.exe

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
    pause
    goto endif1
:else1
    copy /Y %FROMDIR%\%FROMFILE% %TODIR%\%TOFILE% > Nul 2> Nul
    if NOT exist %TODIR%\%TOFILE% goto else2
      echo %FROMFILE% copied to %TODIR%\%TOFILE%
      goto endif2
:else2
      echo ***error: %FROMFILE% could not be copied to %TODIR%
      pause
:endif2
:endif1
exit /b

:eof


