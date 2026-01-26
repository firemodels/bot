@echo off
setlocal
:: release info
set versionbase=%1
set zipbase=%versionbase%_win
set SMVEDITION=SMV6

set scriptdir=%~dp0
cd %scriptdir%
cd ..\..\..
set reporoot=%CD%

:: Windows batch file to build a smokeview bundle

set CURDIR=%CD%

set smvbuild=%reporoot%\smv\Build\smokeview\intel_win
set forbundle=%reporoot%\smv\Build\for_bundle
set smvscripts=%reporoot%\smv\scripts
set svzipbuild=%reporoot%\smv\Build\smokezip\intel_win
set svdiffbuild=%reporoot%\smv\Build\smokediff\intel_win
set pnginfobuild=%reporoot%\smv\Build\pnginfo\intel_win
set fds2fedbuild=%reporoot%\smv\Build\fds2fed\intel_win
set bgbuild=%reporoot%\smv\Build\background\intel_win
set flushfilebuild=%reporoot%\smv\Build\flush\intel_win
set timepbuild=%reporoot%\smv\Build\timep\intel_win
set windbuild=%reporoot%\smv\Build\wind2fds\intel_win
set sh2bat=%reporoot%\smv\Build\sh2bat\intel_win
set gettime=%reporoot%\smv\Build\get_time\intel_win
set repoexes=%userprofile%\.bundle\BUNDLE\WINDOWS\repoexes

set smvdir=%zipbase%\%SMVEDITION%

cd %userprofile%
if NOT exist .bundle mkdir .bundle
cd .bundle
if NOT exist bundles mkdir bundles
cd bundles
set bundles=%CD%

echo.
echo --- filling distribution directory ---
echo.
IF EXIST %smvdir% rmdir /S /Q %smvdir%
mkdir %smvdir%

CALL :COPY  %reporoot%\smv\Build\set_path\intel_win\set_path_win.exe "%smvdir%\set_path.exe"
CALL :COPY  %smvbuild%\smokeview_win.exe                              %smvdir%\smokeview.exe
CALL :COPY  %smvscripts%\jp2conv.bat                                  %smvdir%\jp2conv.bat

::echo copying .po files
::copy %forbundle%\*.po %smvdir%\.>Nul

echo copying .png files
copy %forbundle%\*.png %smvdir%\.>Nul

CALL :COPY  %forbundle%\volrender.ssf %smvdir%\volrender.ssf

CALL :COPY  %bgbuild%\background_win.exe     %smvdir%\background.exe
CALL :COPY  %flushfilebuild%\flush_win.exe   %smvdir%\flush.exe
CALL :COPY  %svdiffbuild%\smokediff_win.exe  %smvdir%\smokediff.exe
CALL :COPY  %pnginfobuild%\pnginfo_win.exe   %smvdir%\pnginfo.exe
CALL :COPY  %fds2fedbuild%\fds2fed_win.exe   %smvdir%\fds2fed.exe
CALL :COPY  %svzipbuild%\smokezip_win.exe    %smvdir%\smokezip.exe
CALL :COPY  %timepbuild%\timep_win.exe       %smvdir%\timep.exe
CALL :COPY  %windbuild%\wind2fds_win.exe     %smvdir%\wind2fds.exe

echo Unpacking Smokeview %versionbase% installation files > %forbundle%\unpack.txt
echo Updating Windows Smokeview to %versionbase%          > %forbundle%\message.txt

CALL :COPY  "%forbundle%\message.txt"                         %zipbase%\message.txt
CALL :COPY  %forbundle%\setup.bat                             %zipbase%\setup.bat

set curdir=%CD%

CALL :COPY  %forbundle%\smokeview.ini           %smvdir%\smokeview.ini

echo copying textures
mkdir %smvdir%\textures
copy %forbundle%\textures\*.jpg %smvdir%\textures>Nul
copy %forbundle%\textures\*.png %smvdir%\textures>Nul

echo copying colorbars
mkdir %smvdir%\colorbars
mkdir %smvdir%\colorbars\linear
mkdir %smvdir%\colorbars\rainbow
mkdir %smvdir%\colorbars\divergent
mkdir %smvdir%\colorbars\circular

copy %forbundle%\colorbars\linear\*.csv    %smvdir%\colorbars\linear    >Nul
copy %forbundle%\colorbars\rainbow\*.csv   %smvdir%\colorbars\rainbow   >Nul
copy %forbundle%\colorbars\divergent\*.csv %smvdir%\colorbars\divergent >Nul
copy %forbundle%\colorbars\circular\*.csv  %smvdir%\colorbars\circular  >Nul

CALL :COPY  %forbundle%\objects.svo                   %smvdir%\.
CALL :COPY  %sh2bat%\sh2bat_win.exe                   %smvdir%\sh2bat.exe
CALL :COPY  %gettime%\get_time_win.exe                %smvdir%\get_time.exe
CALL :COPY  %reporoot%\webpages\SMV_Release_Notes.htm %smvdir%\release_notes.html
CALL :COPY  %forbundle%\.smokeview_bin                %smvdir%\.

call :IS_FILE_INSTALLED clamscan
set basedir=%bundles%\%zipbase%
set basename=%zipbase%
set logdir=%reporoot%\bot\Bundlebot\nightly\output
if not exist %basedir% error ***error: %basedir% does not exist
if %ERRORLEVEL% == 1 goto elsescan
  if not exist %basedir% goto 
  set ADDSHA256=%reporoot%\bot\Bundlebot\nightly\add_sha256.bat
  set CSV2HTML=%reporoot%\bot\Bundlebot\nightly\csv2html.bat
  set scanlog=%logdir%\%basename%_log.txt
  set vscanlog=%logdir%\%basename%.csv
  set preamble=%logdir%\preamble.csv
  set summary=%logdir%\summary.txt
  set htmllog=%logdir%\%basename%_manifest.html
  set nvscanlog=%logdir%\%basename%_nlog.txt
  echo ***scanning bundle
  echo    input: %basedir%
  echo    output: %vscanlog%
  clamscan -r %basedir% > %scanlog% 2>&1
  echo ***adding sha256 hashes
  cd %reporoot%\bot\Bundlebot\nightly\
  call %ADDSHA256% %scanlog%         > %vscanlog%
  cd %reporoot%\bot\Bundlebot\nightly\
  echo ***removing %basename% from filepaths
  sed -i.bak "s/%basename%\\//g"   %vscanlog%

:: split file into two parts
  sed "/SCAN SUMMARY/,$ d"    %vscanlog% > %preamble%
  sed -n "/SCAN SUMMARY/,$ p" %vscanlog% > %summary%

:: sort the first part
  sort %preamble% > %vscanlog%

:: remove adjacent commas ,, and append to original file
  sed "s/,,/ /g" %summary%     >> %vscanlog%

  cd %reporoot%\bot\Bundlebot\nightly\
  echo ***converting scan log to html
  call %CSV2HTML% %vscanlog%
  if NOT exist %htmllog% echo ***error: %htmllog% does not exist
  if NOT exist %htmllog% goto skiphtml
  CALL :COPY %htmllog% %out_doc%\SmvManifest.html
  CALL :COPY %htmllog% %bundles%\%basename%_manifest.html
  :skiphtml
  
  echo complete
  cd %reporoot%\bot\Bundlebot\nightly\
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
echo --- compressing distribution directory ---
echo.
cd %bundles%\%zipbase%
if exist ..\%zipbase%.zip erase ..\%zipbase%.zip
if exist ..\%zipbase%.exe erase ..\%zipbase%.exe
wzzip -a -r -P ..\%zipbase%.zip * >Nul

cd ..

echo.
echo --- creating installer ---
echo.
wzipse32 %zipbase%.zip -runasadmin -setup -auto -i %forbundle%\icon.ico -t %forbundle%\unpack.txt -a %forbundle%\about.txt -st"Smokeview %smv_version% Setup" -o -c cmd /k setup.bat

if not exist %zipbase%.exe echo ***warning: %zipbase%.exe was not created
if     exist %zipbase%.exe CALL :COPY %zipbase%.exe %bundles%\%basename%.exe

echo.
echo --- Windows Smokeview installer, %zipbase%.exe, built
echo.

cd %CURDIR%
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

:: -------------------------------------------------------------
:COPY
:: -------------------------------------------------------------
set label=%~n1%~x1
set infile=%1
set infiletime=%~t1
set outfile=%2
IF EXIST %infile% (
   echo copying %label%
   echo from: %infile%
   echo to: %outfile%
   echo.
   copy %infile% %outfile% >Nul
) ELSE (
   echo.
   echo *** warning: %infile% does not exist
   echo.
   pause
)
exit /b

:EOF
