goto eof

:is_fds_installed
set errorlevel=0
set fdsinstalled=0
where fds
if %errorlevel% == 1 exit /b 1
set fdsinstalled=1
exit /b 0

:eof
