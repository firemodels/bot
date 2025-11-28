@echo off
setlocal
set outfile=%userprofile%\.bundle\bundle_fdssmv_nightly.out

:: the windows task scheduler which builds bundles every day call this script to make sure 
:: the bot repo (ie the BuildNightly.bat script) is up to date.  A wrapper script is necessary
:: because a script CANNOT be updated while it is running but in this case CAN be updated
:: before it is run

set CURDIRW=%CD%
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Updating bot repo
cd ..\..\Scripts
call update_repos -b -m > Nul 2>&1

cd %CURDIRW%
call BuildNightly > %outfile% 2>&1
cd %CURDIRW%
