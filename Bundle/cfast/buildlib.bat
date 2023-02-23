@echo off
set fromfile=%1
set tofile=%2
if exist finished erase finished
call makelib
copy %fromfile% %tofile%
echo finished > finished
exit