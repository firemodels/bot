@echo off
set platform=%1
set GH_OWNER=%GH_SMOKEVIEW_OWNER%
set SMOKEVIEW_TAG=%GH_SMOKEVIEW_TAG%

::  batch file to build test or release Smokeview on a Windows, OSX or Linux system

:: setup environment variables (defining where repository resides etc) 

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

%git_drive%
call %envfile%

set uploaddir=%userprofile%\.bundle\bundles
set CURDIR=%CD%
set gawk=%git_root%\bot\Scripts\bin\gawk.exe

if NOT "%platform%" == "Windows" goto endif1
  set filelist=%TEMP%\smv_files_win.out
  gh release view %SMOKEVIEW_TAG%  -R github.com/%GH_OWNER%/%GH_REPO% | grep SMV | grep -v FDS | grep -v CFAST | grep win | %gawk% "{print $2}" > %filelist%
  for /F "tokens=*" %%A in (%filelist%) do gh release delete-asset %SMOKEVIEW_TAG% %%A  -R github.com/%GH_OWNER%/%GH_REPO% -y
  erase %filelist%

  gh release upload %SMOKEVIEW_TAG% %uploaddir%\%smv_revision%_win.exe            -R github.com/%GH_OWNER%/%GH_REPO% --clobber
  gh release upload %SMOKEVIEW_TAG% %uploaddir%\%smv_revision%_win_manifest.html  -R github.com/%GH_OWNER%/%GH_REPO% --clobber
:endif1

if NOT "%platform%" == "Linux" goto endif2
  set outfile=%TEMP%\files_lnx.out
  gh release view %SMOKEVIEW_TAG% -R github.com/%GH_OWNER%/%GH_REPO% | grep SMV | grep -v FDS | grep -v CFAST | grep lnx | %gawk% "{print $2}" > %outfile%
  for /F "tokens=*" %%A in (%outfile%) do gh release delete-asset %SMOKEVIEW_TAG% %%A -R github.com/%GH_OWNER%/%GH_REPO% -y
  erase %outfile%

  plink %plink_options% %linux_logon%  %linux_git_root%/bot/Bundlebot/nightly/upload_smvbundle_custom.sh .bundle/bundles %smv_revision%_lnx.sh              %linux_git_root%/bot/Bundlebot/nightly %SMOKEVIEW_TAG% %GH_OWNER% %GH_REPO%
  plink %plink_options% %linux_logon%  %linux_git_root%/bot/Bundlebot/nightly/upload_smvbundle_custom.sh .bundle/bundles %smv_revision%_lnx_manifest.html   %linux_git_root%/bot/Bundlebot/nightly %SMOKEVIEW_TAG% %GH_OWNER% %GH_REPO%
:endif2

if NOT "%platform%" == "OSX" goto endif3
  set outfile=%TEMP%\files_osx.out
  gh release view %SMOKEVIEW_TAG% -R github.com/%GH_OWNER%/%GH_REPO% | grep SMV | grep -v FDS | grep -v CFAST | grep osx | %gawk% "{print $2}" > %outfile%
  for /F "tokens=*" %%A in (%outfile%) do gh release delete-asset %SMOKEVIEW_TAG% %%A -R github.com/%GH_OWNER%/%GH_REPO% -y
  erase %outfile%

  plink %plink_options% %osx_logon%  %linux_git_root%/bot/Bundlebot/nightly/upload_smvbundle_custom.sh .bundle/bundles %smv_revision%_osx.sh              %linux_git_root%/bot/Bundlebot %SMOKEVIEW_TAG% %GH_OWNER% %GH_REPO%
  plink %plink_options% %osx_logon%  %linux_git_root%/bot/Bundlebot/nightly/upload_smvbundle_custom.sh .bundle/bundles %smv_revision%_osx_manifest.html   %linux_git_root%/bot/Bundlebot %SMOKEVIEW_TAG% %GH_OWNER% %GH_REPO%
:endif3

start chrome https://github.com/%GH_OWNER%/%GH_REPO%/releases/tag/%SMOKEVIEW_TAG%
echo.
echo upload complete
pause

exit /b
