@echo off
SETLOCAL

set THISDIR=%CD%

cd ..\..\..
set GITROOT=%CD%
cd %THISDIR%

set CFASTREPO=%GITROOT%\cfast
set SCRIPTDIR=%CFASTREPO%\Utilities\for_bundle\scripts
set VSSTUDIO=%CFASTREPO%\Utilities\Visual_Studio

cd %CFASTREPO%
git clean -dxf

cd %THISDIR%
call Restore_vs_config %VSSTUDIO%

cd %THISDIR%
call CopyFilestoCFASTclean

cd %SCRIPTDIR%
call BUNDLE_cfast

cd %THISDIR%
