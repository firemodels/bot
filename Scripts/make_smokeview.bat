@echo off

:: setup compiler environment
call setup_intel_compilers.bat

set SMV_TESTFLAG=
set SMV_TESTSTRING=

Title Building Smokeview for 64 bit Windows
set SMV_TESTFLAG=
set SMV_TESTSTRING=
::  set SMV_TESTFLAG=-D pp_BETA
::  set SMV_TESTSTRING=test_

set SMV_TESTFLAG=%SMV_TESTFLAG% -D pp_WIN_ONEAPI

set GLUT=glut

set CURDIR=%CD%


cd ..\..\smv\Build\smokeview\intel_win_64
erase *.obj *.mod *.exe 2> Nul
make -j 4 GLUT="%GLUT%" SHELL="%ComSpec%" SMV_TESTFLAG="%SMV_TESTFLAG%" SMV_TESTSTRING="%SMV_TESTSTRING%" -f ..\Makefile intel_win_64
cd %CURDIR%
pause

