@echo off
setlocal
set bot=%1
set FDS_REVISION_ARG=%2
set SMV_REVISION_ARG=%3
set nightly=%4

set FDSMAJORVERSION=6
set FDSEDITION=FDS6
set SMVEDITION=SMV6

set fdsversion=%FDSEDITION%
set smvversion=%SMVEDITION%

:: get git root directory

set scriptdir=%~dp0
set curdir=%CD%
cd %scriptdir%\..\..
set repo_root=%CD%
cd %scriptdir%
set SVNROOT=%repo_root%

:: setup .bundle and upload directories

set bundle_dir=%userprofile%\.bundle
if NOT exist %bundle_dir% mkdir %bundle_dir%

set upload_dir=%userprofile%\.bundle\uploads
if NOT exist %upload_dir% mkdir %upload_dir%

set bundles_dir=%userprofile%\.bundle\bundles
if NOT exist %bundles_dir% mkdir %bundles_dir%

if "%env_defined%" == "1" goto endif_env_defined
set envfile="%userprofile%"\fds_smv_env.bat
IF EXIST %envfile% GOTO endif_envexist2
echo ***Fatal error.  The environment setup file %envfile% does not exist. 
echo Create a file named %envfile% and use smv/scripts/fds_smv_env_template.bat
echo as an example.
echo.
echo Aborting now...
if "x%bot%" == "xbot" goto skip1
  pause>Nul
:skip1
goto:eof

:endif_envexist2

call %envfile%
:endif_env_defined

if "x%FDS_REVISION_ARG%" == "x" goto skip_fds_version
  set fds_version=%FDS_REVISION_ARG%
:skip_fds_version

if "x%SMV_REVISION_ARG%" == "x" goto skip_smv_version
  set smv_version=%SMV_REVISION_ARG%
:skip_smv_version

if NOT "x%nightly%" == "xnull" goto skip_nightly_null
  set nightly=
:skip_nightly_null

if "x%nightly%" == "x" goto skip_nightly
  set nightly=_%nightly%
:skip_nightly

set      in_impi=%userprofile%\.bundle\BUNDLE\WINDOWS\%INTELVERSION%
set in_intel_dll=%userprofile%\.bundle\BUNDLE\WINDOWS\%INTELVERSION%
set  in_shortcut=%userprofile%\.bundle\BUNDLE\WINDOWS\repoexes

set basename=%fds_version%_%smv_version%%nightly%_win
set hashfile=%repo_root%\smv\Build\hashfile\intel_win_64\hashfile_win_64.exe
if exist %hashfile% goto endif0
  echo ***warning: %hashfile% does not exist
  echo Bundle will not contain hashes of application files
if "x%bot%" == "xbot" goto skip2
  pause
:skip2
:endif0

set in_pdf=%userprofile%\.bundle\pubs
set smv_forbundle=%repo_root%\bot\Bundle\smv\for_bundle

set basedir=%upload_dir%\%basename%

set out_bundle=%basedir%\firemodels
set out_bin=%out_bundle%\%fdsversion%\bin
set out_fdshash=%out_bundle%\%fdsversion%\bin\hash
set out_uninstall=%out_bundle%\%fdsversion%\Uninstall
set out_doc=%out_bundle%\%fdsversion%\Documentation
set out_guides="%out_doc%\Guides_and_Release_Notes"
set out_web="%out_doc%\FDS_on_the_Web"
set out_examples=%out_bundle%\%fdsversion%\Examples
set fds_examples=%repo_root%\fds\Verification
set smv_examples=%repo_root%\smv\Verification

set out_smv=%out_bundle%\%smvversion%
set out_textures=%out_smv%\textures
set out_smvhash=%out_smv%\hash

set fds_casessh=%repo_root%\fds\Verification\FDS_Cases.sh
set fds_casesbat=%repo_root%\fds\Verification\FDS_Cases.bat
set smv_casessh=%repo_root%\smv\Verification\scripts\SMV_Cases.sh
set smv_casesbat=%repo_root%\smv\Verification\scripts\SMV_Cases.bat
set wui_casessh=%repo_root%\smv\Verification\scripts\WUI_Cases.sh
set wui_casesbat=%repo_root%\smv\Verification\scripts\WUI_Cases.bat
set fds_auxfilesbat=%repo_root%\bot\Bundlebot\copy_fds_aux_files.bat

set copyFDScases=%repo_root%\bot\Bundle\fds\scripts\copyFDScases.bat
set copyCFASTcases=%repo_root%\bot\Bundle\fds\scripts\copyCFASTcases.bat

set fds_forbundle=%repo_root%\bot\Bundle\fds\for_bundle

:: erase the temporary bundle directory if it already exists

if exist %basedir% rmdir /s /q %basedir%

mkdir %basedir%
mkdir %out_bundle%
mkdir %out_bundle%\%fdsversion%
mkdir %out_bundle%\%smvversion%
mkdir %out_bin%
mkdir %out_textures%
mkdir %out_doc%
mkdir %out_guides%
mkdir %out_web%
mkdir %out_examples%
mkdir %out_uninstall%

mkdir %out_fdshash%
mkdir %out_smvhash%

set release_version=%FDSMAJORVERSION%_win_64
set release_version=

echo.
echo --- filling distribution directory ---
echo.


copy %smv_forbundle%\*.po                   %out_bin%\.>Nul

:: initialize manifest file
set MANIFEST=%out_doc%\manifest.html

echo ^<html^>                                  > %MANIFEST%
echo ^<head^>                                 >> %MANIFEST%
echo ^<TITLE^>                                >> %MANIFEST%
echo Manifest - %basename%^ -                 >> %MANIFEST%
date /t                                       >> %MANIFEST%
time /t                                       >> %MANIFEST%
echo ^</TITLE^>                               >> %MANIFEST%
echo ^</HEAD^>                                >> %MANIFEST%
echo ^<BODY BGCOLOR="#FFFFFF" ^>              >> %MANIFEST%
echo ^<h2^>                                   >> %MANIFEST%
echo Manifest - %basename%^ -                 >> %MANIFEST%
date /t                                       >> %MANIFEST%
time /t                                       >> %MANIFEST%
echo ^</h2^>                                  >> %MANIFEST%


CALL :COPY  %bundle_dir%\fds\fds.exe        %out_bin%\fds.exe
CALL :COPY  %bundle_dir%\fds\fds2ascii.exe  %out_bin%\fds2ascii.exe
CALL :COPY  %bundle_dir%\fds\test_mpi.exe   %out_bin%\test_mpi.exe

CALL :COPY  %bundle_dir%\smv\smokeview.exe  %out_smv%\smokeview.exe

CALL :TOMANIFESTFDS   %out_bin%\fds.exe          fds

set curdir=%CD%
cd %out_bin%

:: copy run-time mpi files
mkdir mpi
CALL :COPYDIR %in_impi%\mpi mpi
cd %CURDIR%
CALL :TOMANIFESTMPI   %out_bin%\mpi\mpiexec.exe  mpiexec

CALL :TOMANIFESTSMV   %out_smv%\smokeview.exe    smokeview

CALL :COPY  %bundle_dir%\smv\background.exe %out_bin%\background.exe
CALL :COPY  %bundle_dir%\smv\hashfile.exe   %out_smv%\hashfile.exe 
CALL :COPY  %bundle_dir%\smv\smokediff.exe  %out_smv%\smokediff.exe
CALL :COPY  %bundle_dir%\smv\smokezip.exe   %out_smv%\smokezip.exe 
CALL :COPY  %bundle_dir%\smv\wind2fds.exe   %out_smv%\wind2fds.exe 

CALL :TOMANIFESTSMV   %out_bin%\background.exe background
CALL :TOMANIFESTLIST  %out_bin%\fds2ascii.exe  fds2ascii
CALL :TOMANIFESTSMV   %out_smv%\hashfile.exe   hashfile
CALL :TOMANIFESTSMV   %out_smv%\smokediff.exe  smokediff
CALL :TOMANIFESTSMV   %out_smv%\smokezip.exe   smokezip
CALL :TOMANIFESTLIST  %out_bin%\test_mpi.exe   test_mpi
CALL :TOMANIFESTSMV   %out_smv%\wind2fds.exe   wind2fds

:: wrap up manifest file

echo ^</body^>                                  >> %MANIFEST%
echo ^</html^>                                  >> %MANIFEST%

CALL :COPY  %repo_root%\smv\scripts\jp2conv.bat                                %out_smv%\jp2conv.bat

set curdir=%CD%
cd %out_bin%

%hashfile% fds.exe        >  hash\fds_%fds_version%.exe.sha1
%hashfile% fds2ascii.exe  >  hash\fds2ascii_%fds_version%.exe.sha1
%hashfile% background.exe >  hash\background_%fds_version%.exe.sha1
%hashfile% test_mpi.exe   >  hash\test_mpi_%fds_version%.exe.sha1
cd hash
cat *.sha1              >  %upload_dir%\%basename%.sha1

cd %out_smv%
%hashfile% hashfile.exe   >  hash\hashfile_%smv_version%.exe.sha1
%hashfile% smokeview.exe  >  hash\smokeview_%smv_version%.exe.sha1
%hashfile% smokediff.exe  >  hash\smokediff_%smv_version%.exe.sha1
%hashfile% smokezip.exe   >  hash\smokezip_%smv_version%.exe.sha1
%hashfile% wind2fds.exe   >  hash\wind2fds_%smv_version%.exe.sha1
cd hash
cat *.sha1              >>  %upload_dir%\%basename%.sha1

cd %curdir%
CALL :COPY %in_intel_dll%\libiomp5md.dll                        %out_bin%\libiomp5md.dll
CALL :COPY "%fds_forbundle%\fdsinit.bat"                        %out_bin%\fdsinit.bat
CALL :COPY "%fds_forbundle%\fdspath.bat"                        %out_bin%\fdspath.bat
CALL :COPY "%fds_forbundle%\helpfds.bat"                        %out_bin%\helpfds.bat
CALL :COPY "%fds_forbundle%\fds_local.bat"                      %out_bin%\fds_local.bat
CALL :COPY  %repo_root%\smv\Build\sh2bat\intel_win_64\sh2bat.exe %out_bin%\sh2bat.exe

:: setup program for new installer
CALL :COPY "%fds_forbundle%\setup.bat"                          %out_bundle%\setup.bat
echo %basename%                                               > %out_bundle%\basename.txt

echo Installing %FDS_REVISION_ARG% and %SMV_REVISION_ARG% on Windows        > %fds_forbundle%\message.txt
CALL :COPY  "%fds_forbundle%\message.txt"                            %out_bundle%\message.txt
echo Unpacking %FDS_REVISION_ARG% and %SMV_REVISION_ARG% installation files > %fds_forbundle%\unpack.txt

echo.
echo --- copying auxillary files ---
echo.
CALL :COPY  %smv_forbundle%\objects.svo    %out_smv%\.
CALL :COPY  %smv_forbundle%\volrender.ssf  %out_smv%\.
CALL :COPY  %smv_forbundle%\smokeview.ini  %out_smv%\.
CALL :COPY  %smv_forbundle%\smokeview.ini  %out_smv%\.
CALL :COPY  %smv_forbundle%\smokeview.html %out_smv%\.


echo copying textures
copy %smv_forbundle%\textures\*.jpg          %out_textures%\.>Nul
copy %smv_forbundle%\textures\*.png          %out_textures%\.>Nul

echo.
echo --- copying uninstaller ---
echo.
CALL :COPY  "%fds_forbundle%\uninstall_fds.bat"  "%out_uninstall%\uninstall_base.bat"
CALL :COPY  "%fds_forbundle%\uninstall_fds2.bat" "%out_uninstall%\uninstall_base2.bat"
CALL :COPY  "%fds_forbundle%\uninstall.bat"      "%out_uninstall%\uninstall.bat"
echo @echo off > "%out_uninstall%\uninstall.vbs"

CALL :COPY  "%repo_root%\smv\Build\set_path\intel_win_64\set_path_win_64.exe" "%out_uninstall%\set_path.exe"

echo.
echo --- copying FDS documentation ---
echo.

CALL :COPY  "%repo_root%\webpages\FDS_Release_Notes.htm" %out_guides%\FDS_Release_Notes.htm
CALL :COPY  %in_pdf%\FDS_Config_Management_Plan.pdf      %out_guides%\.
CALL :COPY  %in_pdf%\FDS_User_Guide.pdf                  %out_guides%\.
CALL :COPY  %in_pdf%\FDS_Technical_Reference_Guide.pdf   %out_guides%\.
CALL :COPY  %in_pdf%\FDS_Validation_Guide.pdf            %out_guides%\.
CALL :COPY  %in_pdf%\FDS_Verification_Guide.pdf          %out_guides%\.

echo.
echo --- copying Smokeview documentation ---
echo.

CALL :COPY %in_pdf%\SMV_User_Guide.pdf                %out_guides%\.
CALL :COPY %in_pdf%\SMV_Technical_Reference_Guide.pdf %out_guides%\.
CALL :COPY %in_pdf%\SMV_Verification_Guide.pdf        %out_guides%\.

echo.
echo --- copying startup shortcuts ---
echo.
 
CALL :COPY "%repo_root%\webpages\smv_readme.html"      "%out_guides%\Smokeview_release_notes.html"
CALL :COPY "%fds_forbundle%\Overview.html"             "%out_doc%\Overview.html"
CALL :COPY "%fds_forbundle%\FDS_Web_Site.url"          "%out_web%\Official_Web_Site.url"

echo.
echo --- copying example files ---

set outdir=%out_examples%
set QFDS=call %copyFDScases%
set RUNTFDS=call %copyFDScases%
set RUNCFAST=call %copyCFASTcases%

cd %fds_examples%
%repo_root%\smv\Build\sh2bat\intel_win_64\sh2bat %fds_casessh% %fds_casesbat%
call %fds_casesbat%>Nul
call %fds_auxfilesbat% %fds_examples% %out_examples%

cd %smv_examples%
%repo_root%\smv\Build\sh2bat\intel_win_64\sh2bat %smv_casessh% %smv_casesbat%
call %smv_casesbat%>Nul
%repo_root%\smv\Build\sh2bat\intel_win_64\sh2bat %wui_casessh% %wui_casesbat%
call %wui_casesbat%>Nul

echo.
echo --- copying scripts that finalize installation ---
echo.

CALL :COPY  "%fds_forbundle%\setup_fds_firewall.bat" "%out_bundle%\%fdsversion%\setup_fds_firewall.bat"
CALL :COPY  "%in_shortcut%\shortcut.exe"             "%out_bundle%\%fdsversion%\shortcut.exe"

echo.
echo --- compressing distribution ---

cd %upload_dir%
if exist %basename%.zip erase %basename%.zip

cd %out_bundle%\..
wzzip -a -r -xExamples\*.csv -P ..\%basename%.zip firemodels > Nul

:: create a self extracting installation file from the zipped bundle directory

echo.
echo --- creating installer ---

cd %upload_dir%
echo Press Setup to begin installation. > %fds_forbundle%\main.txt
if exist %basename%.exe erase %basename%.exe

wzipse32 %basename%.zip -setup -auto -i %fds_forbundle%\icon.ico -t %fds_forbundle%\unpack.txt -runasadmin -a %fds_forbundle%\about.txt -st"%fds_version% %smv_version%" -o -c cmd /k firemodels\setup.bat

%hashfile% %basename%.exe   >>  %upload_dir%\%basename%.sha1

CALL :COPY %upload_dir%\%basename%.exe  %bundles_dir%\%basename%.exe
CALL :COPY %upload_dir%\%basename%.sha1 %bundles_dir%\%basename%.sha1
CALL :COPY %MANIFEST%                   %upload_dir%\%basename%_manifest.html

echo.
echo --- installer built ---

cd %CURDIR%>Nul

GOTO EOF

::------------------------------------------------
:TOMANIFESTLIST
::------------------------------------------------

set  prog=%1
set  desc=%2

echo ^<p^>^<hr^>^<p^>             >> %MANIFEST%
if NOT EXIST %prog% goto else_list
    echo ^<pre^>                  >> %MANIFEST%
    echo %desc% is present        >> %MANIFEST%
    echo ^</pre^>                 >> %MANIFEST%
    goto endif_list
:else_smv
    echo %desc% is absent^<br^>   >> %MANIFEST%
    echo %prog"                   >> %MANIFEST%
  fi
  echo ^<br^>                     >> %MANIFEST%
:endif_list
exit /b

::------------------------------------------------
:TOMANIFESTSMV
::------------------------------------------------

set  prog=%1
set  desc=%2

echo ^<p^>^<hr^>^<p^>             >> %MANIFEST%
if NOT EXIST %prog% goto else_smv
  echo ^<pre^>                    >> %MANIFEST%
    %prog% -v                     >> %MANIFEST%
    echo ^</pre^>                 >> %MANIFEST%
    goto endif_smv
:else_smv
    echo %desc% is absent^<br^>   >> %MANIFEST%
    echo %prog"                   >> %MANIFEST%
  fi
  echo ^<br^>                     >> %MANIFEST%
:endif_smv
exit /b

::------------------------------------------------
:TOMANIFESTFDS
::------------------------------------------------

set  prog=%1
set  desc=%2

echo ^<p^>^<hr^>^<p^>             >> %MANIFEST%
if NOT EXIST %prog% goto else_fds
  echo ^<pre^>                    >> %MANIFEST%
  echo. | %prog%                  >> %MANIFEST% 2>&1
  echo ^</pre^>                   >> %MANIFEST%
  goto endif_fds
:else_fds
  echo %desc% is absent^<br^>     >> %MANIFEST%
  echo %prog"                     >> %MANIFEST%
  echo ^<br^>                     >> %MANIFEST%
:endif_fds
exit /b

::------------------------------------------------
:TOMANIFESTMPI
::------------------------------------------------

set  prog=%1
set  desc=%2

echo ^<p^>^<hr^>^<p^>             >> %MANIFEST%
if NOT EXIST %prog% goto else_mpi
  echo ^<pre^>                    >> %MANIFEST%
  echo mpiexec                    >> %MANIFEST%
  echo.                           >> %MANIFEST%
  %prog% --version                >> %MANIFEST% 2>&1
  echo ^</pre^>                   >> %MANIFEST%
  goto endif_mpi
:else_mpi
  echo %desc% is absent^<br^>     >> %MANIFEST%
  echo %prog"                     >> %MANIFEST%
  echo ^<br^>                     >> %MANIFEST%
:endif_mpi
exit /b

::------------------------------------------------
:COPY
::------------------------------------------------
set label=%~n1%~x1
set infile=%1
set infiletime=%~t1
set outfile=%2
IF NOT EXIST %infile% goto else1
   echo copying %label% %infiletime%
   copy %infile% %outfile% >Nul
   goto endif1
:else1
   echo.
   echo *** warning: %infile% does not exist
   echo.
if "x%bot%" == "xbot" goto skip3
  pause
:skip3
:endif1
exit /b

::------------------------------------------------
:COPYDIR
::------------------------------------------------
set fromdir=%1
set todir=%2
IF NOT EXIST %fromdir% goto else2
   echo copying directory %fromdir%
   copy %fromdir% %todir% >Nul
   goto endif2
:else2
   echo.
   echo *** warning: directory %fromdir% does not exist
   echo.
if "x%bot%" == "xbot" goto skip4
  pause
:skip4
:endif2
exit /b

:EOF
