@echo off
:: the windows task scheduler which builds bundles every day call this script to make sure 
:: the bot repo (ie the BuildNightly.bat script) is up to date.  A wrapper script is necessary
:: because a script CANNOT be updated while it is running but in this case CAN be updated
:: before it is run

set CURDIRW=%CD%
cd ../../Scripts
echo.
echo ------------------------------------------------------
echo ------------------------------------------------------
echo Updating bot repo
call update_repos -m -b > Nul

cd %CURDIRW%
call BuildNightly %*
cd %CURDIRW%
