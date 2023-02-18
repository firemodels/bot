@echo off
SETLOCAL

set THISDIR=%CD%

echo ***Building cfast bundle
cd ..\..\..
set GITROOT=%CD%
cd %THISDIR%

set CFASTREPO=%GITROOT%\cfast
set SCRIPTDIR=%CFASTREPO%\Utilities\for_bundle\scripts
set VSSTUDIO=%CFASTREPO%\Utilities\Visual_Studio

cd %CFASTREPO%
echo ***Cleaning cfast repo
git clean -dxf  > Nul 2>&1

cd %THISDIR%
echo ***Restoring project configuration files 
call Restore_vs_config %VSSTUDIO%  > Nul 2>&1

cd %THISDIR%
call CopyFilestoCFASTclean

cd %THISDIR%
call BUNDLE_cfast

cd %THISDIR%
