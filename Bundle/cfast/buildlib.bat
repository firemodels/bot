@echo off
if exist finished erase finished
call makelib
echo finished > finished