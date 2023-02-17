@echo off
::SETLOCAL

set THISDIR=%CD%

cd ..\..\..\..
set GITROOT=%CD%
cd %THISDIR%

set CFASTREPO=%GITROOT%\cfast
set SCRIPTDIR=%CFASTREPO%\Utilities\for_bundle\scripts
set EXTRAS=%GITROOT%\Extras
set VSSTUDIO=%CFASTREPO%\Utilities\Visual_Studio

cd %VSSTUDIO%
call Restore_vs_config

cd %SCRIPTDIR%
call CopyFilestoCFASTclean

cd %SCRIPTDIR%
call BUNDLE_cfast

cd %THISDIR%



