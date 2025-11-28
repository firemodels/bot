@echo off
setlocal

set outfile=%userprofile%\.bundle\bundle_smv_nightly.out

set CURDIRW=%CD%

echo.                                                        >  %outfile% 2>&1
echo ------------------------------------------------------  >> %outfile% 2>&1
echo ------------------------------------------------------  >> %outfile% 2>&1
echo Updating bot repo                                       >> %outfile% 2>&1
cd ..\..\Scripts
call update_repos -b -m > Nul 2>&1

cd %CURDIRW%
call BuildSmvNightly %*                                      >> %outfile% 2>&1
cd %CURDIRW%
