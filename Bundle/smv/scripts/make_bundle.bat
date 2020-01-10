@echo off
set SMVEDITION=SMV6

:: Windows batch file to build a smokeview bundle

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

set CURDIR=%CD%

call %envfile%

%svn_drive%

set BUILDDIR=intel_win_64
set GNUBUILDDIR=gnu_win_64

set version=%smv_version%
set smvbuild=%svn_root%\smv\Build\smokeview\%BUILDDIR%
set gnusmvbuild=%svn_root%\smv\Build\smokeview\%GNUBUILDDIR%
set forbundle=%svn_root%\bot\Bundle\smv\for_bundle
set webgldir=%svn_root%\bot\Bundle\smv\for_bundle\webgl
set smvscripts=%svn_root%\smv\scripts
set svzipbuild=%svn_root%\smv\Build\smokezip\%BUILDDIR%
set dem2fdsbuild=%svn_root%\smv\Build\dem2fds\%BUILDDIR%
set svdiffbuild=%svn_root%\smv\Build\smokediff\%BUILDDIR%
set bgbuild=%svn_root%\smv\Build\background\intel_win_64
set hashfilebuild=%svn_root%\smv\Build\hashfile\%BUILDDIR%
set flushfilebuild=%svn_root%\smv\Build\flush\%BUILDDIR%
set timepbuild=%svn_root%\smv\Build\timep\%BUILDDIR%
set windbuild=%svn_root%\smv\Build\wind2fds\%BUILDDIR%
set sh2bat=%svn_root%\smv\Build\sh2bat\intel_win_64
set gettime=%svn_root%\smv\Build\get_time\%BUILDDIR%
set hashfileexe=%hashfilebuild%\hashfile_win_64.exe
set repoexes=%userprofile%\.bundle\BUNDLE\WINDOWS\repoexes

set zipbase=%version%_win64
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

CALL :COPY  %svn_root%\smv\Build\set_path\intel_win_64\set_path_win_64.exe "%smvdir%\set_path.exe"

CALL :COPY  %smvbuild%\smokeview_win_64.exe            %smvdir%\smokeview.exe
::CALL :COPY  %gnusmvbuild%\smokeview_win_test_64_db.exe %smvdir%\smokeview_gnu.exe

CALL :COPY  %smvscripts%\jp2conv.bat %smvdir%\jp2conv.bat

echo copying .po files
copy %forbundle%\*.po %smvdir%\.>Nul

echo copying .png files
copy %forbundle%\*.png %smvdir%\.>Nul

CALL :COPY  %forbundle%\volrender.ssf %smvdir%\volrender.ssf
CALL :COPY  %webgldir%\smv2html.bat   %smvdir%\smv2html.bat
::CALL :COPY  %webgldir%\smv_setup.bat  %smvdir%\smv_setup.bat

CALL :COPY  %bgbuild%\background_win_64.exe     %smvdir%\background.exe
CALL :COPY  %dem2fdsbuild%\dem2fds_win_64.exe   %smvdir%\dem2fds.exe
CALL :COPY  %flushfilebuild%\flush_win_64.exe   %smvdir%\flush.exe
CALL :COPY  %hashfilebuild%\hashfile_win_64.exe %smvdir%\hashfile.exe
CALL :COPY  %svdiffbuild%\smokediff_win_64.exe  %smvdir%\smokediff.exe
CALL :COPY  %svzipbuild%\smokezip_win_64.exe    %smvdir%\smokezip.exe
CALL :COPY  %timepbuild%\timep_win_64.exe       %smvdir%\timep.exe
CALL :COPY  %windbuild%\wind2fds_win_64.exe     %smvdir%\wind2fds.exe
CALL :COPY %repoexes%\openvr_api.dll                    %smvdir%\openvr_api.dll

echo Unpacking Smokeview %smv_versionbase% installation files > %forbundle%\unpack.txt
echo Install Smokeview %smv_versionbase%                      > %forbundle%\message.txt

CALL :COPY  "%forbundle%\message.txt"                         %zipbase%\message.txt
CALL :COPY  %forbundle%\setup.bat                             %zipbase%\setup.bat

set curdir=%CD%
cd %smvdir%

%hashfileexe% smokeview.exe  >  hash\smokeview_%revision%.sha1
%hashfileexe% smokezip.exe   >  hash\smokezip_%revision%.sha1
%hashfileexe% smokediff.exe  >  hash\smokediff_%revision%.sha1
%hashfileexe% dem2fds.exe    >  hash\dem2fds_%revision%.sha1
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

CALL :COPY  %forbundle%\objects.svo             %smvdir%\.
CALL :COPY  %sh2bat%\sh2bat.exe                 %smvdir%\.
CALL :COPY  %gettime%\get_time_win_64.exe       %smvdir%\get_time.exe
CALL :COPY  %svn_root%\webpages\smv_readme.html %smvdir%\release_notes.html

echo.
echo --- compressing distribution directory ---
echo.
cd %zipbase%
wzzip -a -r -P ..\%zipbase%.zip * >Nul

cd ..
if exist %zipbase%.exe erase %zipbase%.exe

echo.
echo --- creating installer ---
echo.
wzipse32 %zipbase%.zip -runasadmin -setup -auto -i %forbundle%\icon.ico -t %forbundle%\unpack.txt -a %forbundle%\about.txt -st"Smokeview %smv_version% Setup" -o -c cmd /k setup.bat

if not exist %zipbase%.exe echo ***warning: %zipbase%.exe was not created
%hashfileexe% %zipbase%.exe  >   %smvdir%\hash\%zipbase%.exe.sha1

cd %smvdir%\hash
cat %zipbase%.exe.sha1 >> %uploads%\%zipbase%.sha1

echo.
echo --- Smokeview win64 installer %zipbase%.exe built
echo.

cd %CURDIR%
GOTO :EOF

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


