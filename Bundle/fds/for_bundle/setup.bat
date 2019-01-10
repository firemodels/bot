@echo off
set script_dir=%~dp0

if NOT exist %userprofile%\firemodels goto remove_firemodels
echo removing firemodels
rmdir /S /Q %userprofile%\firemodels
:remove_firemodels

echo copying firemodels
xcopy /E /I /H /Q firemodels %userprofile%\firemodels > Nul

echo press enter key to complete installation
pause > Nul
exit