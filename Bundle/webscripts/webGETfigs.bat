@echo off
setlocal EnableDelayedExpansion
set app=%1
set guide=%2

::  batch to copy smokview/smokebot or fdsfirebot figures to local repo

::  setup environment variables (defining where repository resides etc) 

set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
pause>NUL
goto:eof

:endif_envexist

call %envfile%
echo.

%svn_drive%

if "%app%" == "FDS" goto skip_fds
if "%guide%" == "User" (
  Title Download smokeview user guide images

  cd %svn_root%\smv\Manuals\SMV_User_Guide\SCRIPT_FIGURES
  pscp -P 22 %linux_logon%:%smokebothome%/.smokebot/Manuals/SMV_User_Guide/SCRIPT_FIGURES/* .
  goto eof
)
if "%guide%" == "Verification" (
  Title Download smokeview verification guide images

  cd %svn_root%\smv\Manuals\SMV_Verification_Guide\SCRIPT_FIGURES
  pscp -P 22 %linux_logon%:%smokebothome%/.smokebot/Manuals/SMV_Verification_Guide/SCRIPT_FIGURES/* .
  goto eof
)

:skip_fds
if "%guide%" == "User" (
  Title Download FDS user guide images

  cd %svn_root%\fds\Manuals\FDS_User_Guide\SCRIPT_FIGURES
  pscp -P 22 %linux_logon%:%firebothome%/.firebot/Manuals/FDS_User_Guide/SCRIPT_FIGURES/* .
  goto eof
)
if "%guide%" == "Validation" (
  cd %svn_root%\fds\Manuals\FDS_Validation_Guide\SCRIPT_FIGURES
  for /D %%d in (*) do (
      echo.
      echo copying files from %%d
      cd %%d

      Title Download FDS validation guide %%d images

      pscp -P 22 %linux_logon%:%firebothome%/.firebot/Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/%%d/* .
      cd ..
  )
  goto eof
)
if "%guide%" == "Verification" (
  Title Download FDS verification guide images

  cd %svn_root%\fds\Manuals\FDS_Verification_Guide\SCRIPT_FIGURES
  pscp -P 22 %linux_logon%:%firebothome%/.firebot/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/* .

  Title Download FDS verification guide scatterplot images

  cd %svn_root%\fds\Manuals\fds/FDS_Verification_Guide\SCRIPT_FIGURES\Scatterplots
  pscp -P 22 %linux_logon%:%firebothome%/.firebot/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/Scatterplots/* .
  goto eof
)

:eof
echo.
echo copy complete
pause
