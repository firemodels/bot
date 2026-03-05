@echo off
setlocal
set FDS_REVISION_ARG=%1
set SMV_REVISION_ARG=%2
set nightly=%3

set FDSMAJORVERSION=6
set FDSEDITION=FDS6
set SMVEDITION=SMV6

set fdsversion=%FDSEDITION%
set smvversion=%SMVEDITION%

:: get git root directory

set scriptdir=%~dp0
set curdir=%CD%
set logdir=%curdir%\output
cd %scriptdir%\..\..\..
set GITROOT=%CD%
cd %scriptdir%
set returncode=0
set gawk=%GITROOT%\bot\scripts\bin\gawk.exe

:: setup .bundle and upload directories

set bundle_dir=%userprofile%\.bundle
if NOT exist %bundle_dir% mkdir %bundle_dir%

set upload_dir=%userprofile%\.bundle\bundles
if NOT exist %upload_dir% mkdir %upload_dir%

set bundles_dir=%userprofile%\.bundle\bundles
if NOT exist %bundles_dir% mkdir %bundles_dir%

if "x%FDS_REVISION_ARG%" == "x" goto skip_fds_version
  set fds_version=%FDS_REVISION_ARG%
:skip_fds_version

if "x%SMV_REVISION_ARG%" == "x" goto skip_smv_version
  set smv_version=%SMV_REVISION_ARG%
:skip_smv_version

set NIGHTLYLABEL=
if "%nightly%" == "yes" set NIGHTLYLABEL=_nightly

set  in_shortcut=%userprofile%\.bundle\BUNDLE\WINDOWS\repoexes

call %GITROOT%\bot\Scripts\get_repo_info %GITROOT%\fds 1 > FDSREPODATE.out
set /p FDSREPODATE=<FDSREPODATE.out
erase FDSREPODATE.out

set FDSREPODATE=_%FDSREPODATE%
set FDSREPODATE=

set basename=%fds_version%_%smv_version%%FDSREPODATE%%NIGHTLYLABEL%_win
echo %basename%> %TEMP%\fds_smv_basename.txt
set getrepoinfo=%GITROOT%\bot\Scripts\get_repo_info.bat

set in_pdf=%userprofile%\.bundle\pubs
set smv_forbundle=%GITROOT%\smv\Build\for_bundle

set basedir=%upload_dir%\%basename%

set out_bundle=%basedir%\firemodels
set out_bin=%out_bundle%\%fdsversion%\bin
set out_uninstall=%out_bundle%\%fdsversion%\Uninstall
set out_doc=%out_bundle%\%fdsversion%\Documentation
set out_guides="%out_doc%\Guides_and_Release_Notes"
set out_web="%out_doc%\FDS_on_the_Web"
set out_examples=%out_bundle%\%fdsversion%\Examples
set fds_examples=%GITROOT%\fds\Verification
set smv_examples=%GITROOT%\smv\Verification

set out_smv=%out_bundle%\%smvversion%
set out_textures=%out_smv%\textures
set out_colorbars=%out_smv%\colorbars

set fds_casessh=%GITROOT%\fds\Verification\FDS_Cases.sh
set fds_casesbat=%GITROOT%\fds\Verification\FDS_Cases.bat
set smv_casessh=%GITROOT%\smv\Verification\scripts\SMV_Cases.sh
set smv_casesbat=%GITROOT%\smv\Verification\scripts\SMV_Cases.bat
set wui_casessh=%GITROOT%\smv\Verification\scripts\WUI_Cases.sh
set wui_casesbat=%GITROOT%\smv\Verification\scripts\WUI_Cases.bat

set copyFDScases=%GITROOT%\bot\Bundlebot\fds\scripts\copyFDScases.bat
set copyCFASTcases=%GITROOT%\bot\Bundlebot\fds\scripts\copyCFASTcases.bat

set fds_forbundle=%GITROOT%\fds\Build\for_bundle

:: erase the temporary bundle directory if it already exists

if exist %basedir% rmdir /s /q %basedir%

mkdir %basedir%
mkdir %out_bundle%
mkdir %out_bundle%\%fdsversion%
mkdir %out_bundle%\%smvversion%
mkdir %out_bin%
mkdir %out_textures%
mkdir %out_colorbars%
mkdir %out_colorbars%\linear
mkdir %out_colorbars%\divergent
mkdir %out_colorbars%\rainbow
mkdir %out_colorbars%\circular
mkdir %out_doc%
mkdir %out_guides%
mkdir %out_web%
mkdir %out_examples%
mkdir %out_uninstall%

set release_version=%FDSMAJORVERSION%_win
set release_version=

echo.
echo ***filling bundle directory
echo.


CALL :COPY  %bundle_dir%\fds\fds.exe        %out_bin%\fds.exe
CALL :COPY  %bundle_dir%\fds\fds_openmp.exe %out_bin%\fds_openmp.exe
CALL :COPY  %bundle_dir%\fds\fds2ascii.exe  %out_bin%\fds2ascii.exe
CALL :COPY  %bundle_dir%\fds\test_mpi.exe   %out_bin%\test_mpi.exe

CALL :COPY  %bundle_dir%\smv\smokeview.exe  %out_smv%\smokeview.exe

set curdir=%CD%

:: copy run-time mpi files
cd %scriptdir%
call copy_oneapi_libs.bat %out_bin%
cd %CURDIR%

CALL :COPY  %bundle_dir%\smv\background.exe %out_bin%\background.exe
CALL :COPY  %bundle_dir%\smv\smokediff.exe  %out_smv%\smokediff.exe
CALL :COPY  %bundle_dir%\smv\pnginfo.exe    %out_smv%\pnginfo.exe
CALL :COPY  %bundle_dir%\smv\fds2fed.exe    %out_smv%\fds2fed.exe
CALL :COPY  %bundle_dir%\smv\smokezip.exe   %out_smv%\smokezip.exe 
CALL :COPY  %bundle_dir%\smv\wind2fds.exe   %out_smv%\wind2fds.exe 

CALL :COPY  %GITROOT%\smv\scripts\jp2conv.bat                %out_smv%\jp2conv.bat

set curdir=%CD%

CALL :COPY "%fds_forbundle%\fdsinit.bat"                        %out_bin%\fdsinit.bat
CALL :COPY "%fds_forbundle%\fdspath.bat"                        %out_bin%\fdspath.bat
CALL :COPY "%fds_forbundle%\helpfds.bat"                        %out_bin%\helpfds.bat
CALL :COPY "%fds_forbundle%\fds_local.bat"                      %out_bin%\fds_local.bat
CALL :COPY  %GITROOT%\smv\Build\sh2bat\intel_win\sh2bat_win.exe %out_bin%\sh2bat.exe

:: setup program for new installer
CALL :COPY "%fds_forbundle%\setup.bat"                          %out_bundle%\setup.bat
echo %basename%                                               > %out_bundle%\basename.txt

echo Installing %FDS_REVISION_ARG% and %SMV_REVISION_ARG% on Windows        > %fds_forbundle%\message.txt
CALL :COPY  "%fds_forbundle%\message.txt"                            %out_bundle%\message.txt
echo Unpacking %FDS_REVISION_ARG% and %SMV_REVISION_ARG% installation files > %fds_forbundle%\unpack.txt

echo.
echo ***copying auxillary files
echo.
CALL :COPY  %smv_forbundle%\objects.svo    %out_smv%\.
CALL :COPY  %smv_forbundle%\volrender.ssf  %out_smv%\.
CALL :COPY  %smv_forbundle%\smokeview.ini  %out_smv%\.
CALL :COPY  %smv_forbundle%\smokeview.ini  %out_smv%\.
CALL :COPY  %smv_forbundle%\.smokeview_bin %out_smv%\.

echo.
echo ***copying colorbars
echo.
copy %smv_forbundle%\colorbars\linear\*.csv    %out_colorbars%\linear    >Nul
copy %smv_forbundle%\colorbars\rainbow\*.csv   %out_colorbars%\rainbow   >Nul
copy %smv_forbundle%\colorbars\divergent\*.csv %out_colorbars%\divergent >Nul
copy %smv_forbundle%\colorbars\circular\*.csv  %out_colorbars%\circular  >Nul

echo.
echo ***copying textures
echo.
copy %smv_forbundle%\textures\*.jpg          %out_textures%\.>Nul
copy %smv_forbundle%\textures\*.png          %out_textures%\.>Nul

echo.
echo ***copying uninstaller
echo.
CALL :COPY  "%fds_forbundle%\uninstall_fds.bat"  "%out_uninstall%\uninstall_base.bat"
CALL :COPY  "%fds_forbundle%\uninstall_fds2.bat" "%out_uninstall%\uninstall_base2.bat"
CALL :COPY  "%fds_forbundle%\uninstall.bat"      "%out_uninstall%\uninstall.bat"
echo @echo off > "%out_uninstall%\uninstall.vbs"

CALL :COPY  "%GITROOT%\smv\Build\set_path\intel_win\set_path_win.exe" "%out_uninstall%\set_path.exe"

echo.
echo ***copying FDS documentation
echo.

CALL :COPY  "%GITROOT%\webpages\FDS_Release_Notes.htm"   %out_guides%\FDS_Release_Notes.htm
CALL :COPY  %in_pdf%\FDS_Config_Management_Plan.pdf      %out_guides%\.
CALL :COPY  %in_pdf%\FDS_User_Guide.pdf                  %out_guides%\.
CALL :COPY  %in_pdf%\FDS_Technical_Reference_Guide.pdf   %out_guides%\.
CALL :COPY  %in_pdf%\FDS_Validation_Guide.pdf            %out_guides%\.
CALL :COPY  %in_pdf%\FDS_Verification_Guide.pdf          %out_guides%\.

echo.
echo ***copying Smokeview documentation
echo.

CALL :COPY %in_pdf%\SMV_User_Guide.pdf                %out_guides%\.
CALL :COPY %in_pdf%\SMV_Technical_Reference_Guide.pdf %out_guides%\.
CALL :COPY %in_pdf%\SMV_Verification_Guide.pdf        %out_guides%\.

echo.
echo ***copying startup shortcuts
echo.
 
CALL :COPY "%GITROOT%\webpages\SMV_Release_Notes.htm"   "%out_guides%\Smokeview_release_notes.html"
CALL :COPY "%fds_forbundle%\Overview.html"              "%out_doc%\Overview.html"
CALL :COPY "%fds_forbundle%\FDS_Web_Site.url"           "%out_web%\Official_Web_Site.url"

set outdir=%out_examples%
set QFDS=call %copyFDScases%
set RUNTFDS=call %copyFDScases%
set RUNCFAST=call %copyCFASTcases%

echo.
echo ***copying example files
echo.
cd %fds_examples%
%GITROOT%\smv\Build\sh2bat\intel_win\sh2bat_win %fds_casessh% %fds_casesbat%
call %fds_casesbat%>Nul

cd %smv_examples%
%GITROOT%\smv\Build\sh2bat\intel_win\sh2bat_win %smv_casessh% %smv_casesbat%
call %smv_casesbat%>Nul
%GITROOT%\smv\Build\sh2bat\intel_win\sh2bat_win %wui_casessh% %wui_casesbat%
call %wui_casesbat%>Nul

echo.
echo ***copying scripts that finalize installation
echo.

CALL :COPY  "%fds_forbundle%\setup_fds_firewall.bat" "%out_bundle%\%fdsversion%\setup_fds_firewall.bat"
CALL :COPY  "%in_shortcut%\shortcut.exe"             "%out_bundle%\%fdsversion%\shortcut.exe"

echo.

set have_virus=0
call :IS_FILE_INSTALLED clamscan
if not exist %basedir% error ***error: %basedir% does not exist
if %ERRORLEVEL% == 1 goto elsescan
  if not exist %basedir% goto elsescan
  set ADDSHA256=%scriptdir%\add_sha256.bat
  set CSV2HTML=%scriptdir%\csv2html.bat
  set scanlog=%logdir%\%basename%_log.txt
  set vscanlog=%logdir%\%basename%.csv
  set preamble=%logdir%\preamble.csv
  set summary=%logdir%\summary.txt
  set htmllog=%logdir%\%basename%_manifest.html
  set nvscanlog=%logdir%\%basename%_nlog.txt
  echo.
  echo ***scanning bundle
  echo    input: %basedir%
  echo    output: %vscanlog%
  clamscan -r %basedir% > %scanlog% 2>&1
  echo.
  echo ***adding sha256 hashes
  echo.
  cd %scriptdir%
  call %ADDSHA256% %scanlog%         > %vscanlog%
  cd %scriptdir%
  echo.
  echo ***removing %basename% from filepaths
  echo.
  sed -i.bak "s/%basename%\\//g"   %vscanlog%

:: split file into two parts
  sed "/SCAN SUMMARY/,$ d"    %vscanlog% > %preamble%
  sed -n "/SCAN SUMMARY/,$ p" %vscanlog% > %summary%

:: sort the first part
  sort %preamble% > %vscanlog%

:: remove adjacent commas ,, and append to original file
  sed "s/,,/ /g" %summary%     >> %vscanlog%

  cd %scriptdir%
  echo.
  echo ***converting scan log to html
  call %CSV2HTML% %vscanlog%
  if NOT exist %htmllog% echo ***error: %htmllog% does not exist
  if NOT exist %htmllog% goto skiphtml
  CALL :COPY %htmllog% %out_doc%\Manifest.html
  :skiphtml

  echo complete
  echo.
  cd %scriptdir%
  grep Infected %vscanlog% | %gawk% -F":" "{print $2}" > %nvscanlog%
  set have_virus=1
  set /p ninfected=<%nvscanlog%
  if %ninfected% == 0 set have_virus=0
  type %vscanlog%
  echo.
  if %have_virus% == 1 echo ***error: scan reported a virus in the bundle
  if %have_virus% == 1 set returncode=1
  goto endifscan
:elsescan
  echo ***virus scanner not found - bundle was not scanned for viruses/malware
  set returncode=2
:endifscan

echo.
echo ***compressing bundle
echo.

cd %upload_dir%
if exist %basename%.zip erase %basename%.zip

cd %out_bundle%\..
wzzip -a -r -xExamples\*.csv -P ..\%basename%.zip firemodels > Nul

:: create a self extracting installation file from the zipped bundle directory

echo.
echo ***creating installer
echo.

cd %upload_dir%
echo Press Setup to begin installation. > %fds_forbundle%\main.txt
if exist %basename%.exe erase %basename%.exe

wzipse32 %basename%.zip -setup -auto -i %fds_forbundle%\icon.ico -t %fds_forbundle%\unpack.txt -runasadmin -a %fds_forbundle%\about.txt -st"%fds_version% %smv_version%" -o -c cmd /k firemodels\setup.bat

CALL :COPY %upload_dir%\%basename%.exe       %bundles_dir%\%basename%.exe
CALL :COPY %upload_dir%\%basename%.zip       %bundles_dir%\%basename%.zip

echo.
echo ***installer built
echo.

cd %CURDIR%>Nul

GOTO EOF

:: -------------------------------------------------------------
:IS_FILE_INSTALLED
:: -------------------------------------------------------------

  set program=%1
  %program% --help 1> %temp%\file_exist.txt 2>&1
  type %temp%\file_exist.txt | find /i /c "not recognized" > %temp%\file_exist_count.txt
  set /p nothave=<%temp%\file_exist_count.txt
  if %nothave% == 1 (
    echo ***Warning: %program% not installed or not in path
    exit /b 1
  )
  exit /b 0

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
:endif2
exit /b

:EOF
exit /b %returncode%
