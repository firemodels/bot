@echo off
setlocal
:: release info
set versionbase=%1
set test=%2
set zipbase=%versionbase%_win
set SMVEDITION=SMV6

set scriptdir=%~dp0
cd %scriptdir%
cd ..\..\..
set reporoot=%CD%

:: Windows batch file to build a smokeview bundle

set CURDIR=%CD%

set BUILDDIR=intel_win_64

set smvbuild=%reporoot%\smv\Build\smokeview\%BUILDDIR%
set forbundle=%reporoot%\smv\Build\for_bundle
set webgldir=%reporoot%\smv\Build\for_bundle\webgl
set smvscripts=%reporoot%\smv\scripts
set svzipbuild=%reporoot%\smv\Build\smokezip\%BUILDDIR%
set svdiffbuild=%reporoot%\smv\Build\smokediff\%BUILDDIR%
set pnginfobuild=%reporoot%\smv\Build\pnginfo\%BUILDDIR%
set fds2fedbuild=%reporoot%\smv\Build\fds2fed\%BUILDDIR%
set bgbuild=%reporoot%\smv\Build\background\intel_win_64
set hashfilebuild=%reporoot%\smv\Build\hashfile\%BUILDDIR%
set flushfilebuild=%reporoot%\smv\Build\flush\%BUILDDIR%
set timepbuild=%reporoot%\smv\Build\timep\%BUILDDIR%
set windbuild=%reporoot%\smv\Build\wind2fds\%BUILDDIR%
set sh2bat=%reporoot%\smv\Build\sh2bat\intel_win_64
set gettime=%reporoot%\smv\Build\get_time\%BUILDDIR%
set hashfileexe=%hashfilebuild%\hashfile_win_64.exe
set repoexes=%userprofile%\.bundle\BUNDLE\WINDOWS\repoexes

set smvdir=%zipbase%\%SMVEDITION%

cd %userprofile%
if NOT exist .bundle mkdir .bundle
cd .bundle
if NOT exist uploads mkdir uploads
cd uploads
set uploads=%CD%

echo.
echo --- filling distribution directory ---
echo.
IF EXIST %smvdir% rmdir /S /Q %smvdir%
mkdir %smvdir%
mkdir %smvdir%\hash

CALL :COPY  %reporoot%\smv\Build\set_path\intel_win_64\set_path_win_64.exe "%smvdir%\set_path.exe"
CALL :COPY  %smvbuild%\smokeview_win_%test%64.exe                           %smvdir%\smokeview.exe
CALL :COPY  %smvscripts%\jp2conv.bat                                        %smvdir%\jp2conv.bat

::echo copying .po files
::copy %forbundle%\*.po %smvdir%\.>Nul

echo copying .png files
copy %forbundle%\*.png %smvdir%\.>Nul

CALL :COPY  %forbundle%\volrender.ssf %smvdir%\volrender.ssf
CALL :COPY  %webgldir%\smv2html.bat   %smvdir%\smv2html.bat
::CALL :COPY  %webgldir%\smv_setup.bat  %smvdir%\smv_setup.bat

CALL :COPY  %bgbuild%\background_win_64.exe     %smvdir%\background.exe
CALL :COPY  %flushfilebuild%\flush_win_64.exe   %smvdir%\flush.exe
CALL :COPY  %hashfilebuild%\hashfile_win_64.exe %smvdir%\hashfile.exe
CALL :COPY  %svdiffbuild%\smokediff_win_64.exe  %smvdir%\smokediff.exe
CALL :COPY  %pnginfobuild%\pnginfo_win_64.exe   %smvdir%\pnginfo.exe
CALL :COPY  %fds2fedbuild%\fds2fed_win_64.exe   %smvdir%\fds2fed.exe
CALL :COPY  %svzipbuild%\smokezip_win_64.exe    %smvdir%\smokezip.exe
CALL :COPY  %timepbuild%\timep_win_64.exe       %smvdir%\timep.exe
CALL :COPY  %windbuild%\wind2fds_win_64.exe     %smvdir%\wind2fds.exe

echo Unpacking Smokeview %versionbase% installation files > %forbundle%\unpack.txt
echo Updating Windows Smokeview to %versionbase%          > %forbundle%\message.txt

CALL :COPY  "%forbundle%\message.txt"                         %zipbase%\message.txt
CALL :COPY  %forbundle%\setup.bat                             %zipbase%\setup.bat

set curdir=%CD%
cd %smvdir%

%hashfileexe% smokeview.exe  >  hash\smokeview_%revision%.sha1
%hashfileexe% smokezip.exe   >  hash\smokezip_%revision%.sha1
%hashfileexe% smokediff.exe  >  hash\smokediff_%revision%.sha1
%hashfileexe% pnginfo.exe    >  hash\pnginfo_%revision%.sha1
%hashfileexe% fds2fed.exe    >  hash\fds2fed_%revision%.sha1
%hashfileexe% background.exe >  hash\background_%revision%.sha1
%hashfileexe% hashfile.exe   >  hash\hashfile_%revision%.sha1
%hashfileexe% wind2fds.exe   >  hash\wind2fds_%revision%.sha1
cd hash
cat *.sha1              >  %uploads%\%zipbase%.sha1
cd %curdir%

CALL :COPY  %forbundle%\smokeview.html          %smvdir%\smokeview.html
CALL :COPY  %forbundle%\webvr\smokeview_vr.html %smvdir%\smokeview_vr.html
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
CALL :COPY  %sh2bat%\sh2bat_win_64.exe                %smvdir%\sh2bat.exe
CALL :COPY  %gettime%\get_time_win_64.exe             %smvdir%\get_time.exe
CALL :COPY  %reporoot%\webpages\SMV_Release_Notes.htm %smvdir%\release_notes.html
CALL :COPY  %forbundle%\.smokeview_bin                %smvdir%\.

echo.
echo --- compressing distribution directory ---
echo.
cd %zipbase%
if exist ..\%zipbase%.zip erase ..\%zipbase%.zip
if exist ..\%zipbase%.exe erase ..\%zipbase%.exe
wzzip -a -r -P ..\%zipbase%.zip * >Nul

cd ..

echo.
echo --- creating installer ---
echo.
wzipse32 %zipbase%.zip -runasadmin -setup -auto -i %forbundle%\icon.ico -t %forbundle%\unpack.txt -a %forbundle%\about.txt -st"Smokeview %smv_version% Setup" -o -c cmd /k setup.bat

if not exist %zipbase%.exe echo ***warning: %zipbase%.exe was not created
%hashfileexe% %zipbase%.exe  >   %smvdir%\hash\%zipbase%.exe.sha1

cd %smvdir%\hash
cat %zipbase%.exe.sha1 >> %uploads%\%zipbase%.sha1

echo.
echo --- Windows Smokeview installer, %zipbase%.exe, built
echo.

cd %CURDIR%
GOTO EOF

:COPY
set label=%~n1%~x1
set infile=%1
set infiletime=%~t1
set outfile=%2
IF EXIST %infile% (
   echo copying %label% %infiletime%
   copy %infile% %outfile% >Nul
) ELSE (
   echo.
   echo *** warning: %infile% does not exist
   echo.
   pause
)
exit /b

:EOF
