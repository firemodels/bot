@echo off
set SMVEDITION=SMV6

:: batch file to create a test smokeview bundle

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

cd %userprofile%
if NOT exist .bundle mkdir .bundle
cd .bundle
if NOT exist uploads mkdir uploads
cd uploads
set uploads=%CD%

set version=%smv_revision%
set zipbase=%version%_win64
set smvdir=%uploads%\%zipbase%
set smvscripts=%svn_root%\smv\scripts
set forbundle=%svn_root%\bot\Bundle\smv\for_bundle
set webgldir=%svn_root%\bot\Bundle\smv\for_bundle\webgl
set sh2bat=%svn_root%\smv\Build\sh2bat\intel_win_64
set gettime=%svn_root%\smv\Build\get_time\intel_win_64
set smvbuild=%svn_root%\smv\Build
set repoexes=%userprofile%\.bundle\BUNDLE\WINDOWS\repoexes

cd %forbundle%

echo.
echo --- filling distribution directory ---
echo.
IF EXIST %smvdir% rmdir /S /Q %smvdir%
mkdir %smvdir%
mkdir %smvdir%\hash

CALL :COPY %smvbuild%\smokeview\intel_win_64\smokeview_win_test_64.exe  %smvdir%\smokeview.exe
CALL :COPY %smvbuild%\smokeview\gnu_win_64\smokeview_win_test_64_db.exe %smvdir%\smokeview_gnu.exe

CALL :COPY  %smvscripts%\jp2conv.bat %smvdir%\jp2conv.bat

echo copying .png files
copy %forbundle%\*.png %smvdir%\.>Nul

echo copying .po files
copy %forbundle%\*.po %smvdir%\.>Nul

CALL :COPY %forbundle%\volrender.ssf    %smvdir%\volrender.ssf
CALL :COPY  %webgldir%\smv2html.bat     %smvdir%\smv2html.bat
CALL :COPY %forbundle%\fds_test.bat     %smvdir%\fds_test.txt
CALL :COPY %forbundle%\fdsinit_test.bat %smvdir%\fdsinit_test.txt
CALL :COPY %forbundle%\profile_smv.bat  %smvdir%\profile_smv.bat

CALL :COPY %smvbuild%\background\intel_win_64\background_win_64.exe %smvdir%\background.exe
CALL :COPY %smvbuild%\dem2fds\intel_win_64\dem2fds_win_64.exe       %smvdir%\dem2fds.exe
CALL :COPY %smvbuild%\flush\intel_win_64\flush_win_64.exe           %smvdir%\flush.exe
CALL :COPY %smvbuild%\hashfile\intel_win_64\hashfile_win_64.exe     %smvdir%\hashfile.exe
CALL :COPY %smvbuild%\set_path\intel_win_64\set_path_win_64.exe     %smvdir%\set_path.exe
CALL :COPY %smvbuild%\smokediff\intel_win_64\smokediff_win_64.exe   %smvdir%\smokediff.exe
CALL :COPY %smvbuild%\smokezip\intel_win_64\smokezip_win_64.exe     %smvdir%\smokezip.exe
CALL :COPY %smvbuild%\timep\intel_win_64\timep_win_64.exe           %smvdir%\timep.exe
CALL :COPY %smvbuild%\wind2fds\intel_win_64\wind2fds_win_64.exe     %smvdir%\wind2fds.exe
CALL :COPY %repoexes%\openvr_api.dll                                %smvdir%\openvr_api.dll

set curdir=%CD%
cd %smvdir%

hashfile hashfile.exe   >  hash\hashfile_%smv_revision%.sha1
hashfile background.exe >  hash\background_%smv_revision%.sha1
hashfile dem2fds.exe    >  hash\dem2fds_%smv_revision%.sha1
hashfile set_path.exe   >  hash\set_path_%smv_revision%.sha1
hashfile smokediff.exe  >  hash\smokediff_%smv_revision%.sha1
hashfile smokezip.exe   >  hash\smokezip_%smv_revision%.sha1
hashfile smokeview.exe  >  hash\smokeview_%smv_revision%.sha1
hashfile wind2fds.exe   >  hash\wind2fds_%smv_revision%.sha1
cd hash
cat *.sha1              >  %uploads%\%zipbase%.sha1

cd %curdir%

CALL :COPY %forbundle%\objects.svo               %smvdir%\.
CALL :COPY %sh2bat%\sh2bat_win_64.exe            %smvdir%\sh2bat.exe
CALL :COPY %gettime%\get_time_win_64.exe         %smvdir%\get_time.exe
CALL :COPY %forbundle%\wrapup_smv_install_64.bat %smvdir%\wrapup_smv_install.bat
CALL :COPY %forbundle%\smokeview.ini             %smvdir%\smokeview.ini
CALL :COPY %forbundle%\smokeview.html            %smvdir%\smokeview.html
CALL :COPY %forbundle%\\webvr\smokeview_vr.html  %smvdir%\smokeview_vr.html

echo copying textures
mkdir %smvdir%\textures
copy %forbundle%\textures\*.jpg                  %smvdir%\textures>Nul
copy %forbundle%\textures\*.png                  %smvdir%\textures>Nul

echo.
echo --- compressing distribution directory ---
echo.
cd %smvdir%
wzzip -a -r -p %zipbase%.zip *>Nul
rename %zipbase%.zip smoketest_update.zip
copy smoketest_update.zip ..

echo.
echo --- creating installer ---
echo.
cd ..
if exist smoketest_update.exe erase smoketest_update.exe
wzipse32 smoketest_update.zip -runasadmin -d "c:\Program Files\firemodels\%SMVEDITION%" -c wrapup_smv_install.bat
if exist %zipbase%.exe erase %zipbase%.exe
rename smoketest_update.exe %zipbase%.exe

hashfile %zipbase%.exe  >   %smvdir%\hash\%zipbase%.exe.sha1
cd %smvdir%\hash
cat %zipbase%.exe.sha1 >> %uploads%\%zipbase%.sha1

cd ..\..
if not exist %zipbase%.exe echo ***warning: %zipbase%.exe was not created

echo.
echo --- Smokeview win64 test installer %zipbase%.exe built ---
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

