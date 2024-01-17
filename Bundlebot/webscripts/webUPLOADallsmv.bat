@echo off
set platform=%1
if NOT %platform% == "Windows" goto endif1
  call webUPLOADWinsmv
  exit /b
:endif1

if NOT %platform% == "Linux" goto endif2
  call webUPLOADlnxsmv
  exit /b
:endif2

if NOT %platform% == "OSX" goto endif3
  call webUPLOADosxsmv
  exit /b
:endif3

exit /b
