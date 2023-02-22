@echo off
setlocal
set CURDIR=%CD%
set BUILDLIB=%CURDIR%\buildlib.bat

set OPTS=i

cd ..\..\..\smv\build\libs\intel_win_64


:: setup compiler environment
if x%arg1% == xbot goto skip1
call ..\..\..\Utilities\Scripts\setup_intel_compilers.bat
:skip1

set EXIT_SCRIPT=1


set LIBDIR=%CD%
git clean -dxf

cd ..\..\..\Source
git clean -dxf
set SRCDIR=%CD%

cd ..\Build
set BUILDDIR=%CD%

:: ZLIB
cd %SRCDIR%\zlib128
start "building windows zlib" %BUILDLIB% %OPTS% /MIN -copy libz.lib %LIBDIR%\zlib.lib

:: JPEG
cd %SRCDIR%\jpeg-9b
start "building windows jpeg" %BUILDLIB% %OPTS% /MIN -copy libjpeg.lib  %LIBDIR%\jpeg.lib

:: PNG
cd %SRCDIR%\png-1.6.21
start "building windows png" %BUILDLIB% %OPTS% /MIN -copy libpng.lib %LIBDIR%\png.lib

:: GD
cd %SRCDIR%\gd-2.0.15
start "building windows gd" call %BUILDLIB% %OPTS% /MIN -copy libgd.lib %LIBDIR%\gd.lib

:: GLUT
if x%arg3% == xfreeglut goto skip_glut
cd %SRCDIR%\glut-3.7.6
start "building windows glut" %BUILDLIB% %OPTS% /MIN -copy libglutwin.lib %LIBDIR%\glut32.lib
:skip_glut

:: GLUI
cd %SRCDIR%\glui_v2_1_beta
if x%arg3% == xfreeglut goto skip_glui1
  start "building windows glui" %BUILDLIB% %OPTS% /MIN -copy libglui.lib %LIBDIR%\glui.lib
:skip_glui1

:: pthreads
cd %SRCDIR%\pthreads
start "building windows pthreads" %BUILDLIB% %OPTS% /MIN -copy libpthreads.lib %LIBDIR%\pthreads.lib

cd %CURDIR%

