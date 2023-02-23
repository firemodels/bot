@echo off
setlocal
set CURDIR=%CD%
set BUILDLIB=%CURDIR%\build_lib.bat

set OPTS=i
set STARTOPT=/MIN

cd ..\..\..\smv\build\libs\intel_win_64


call ..\..\..\Utilities\Scripts\setup_intel_compilers.bat > Nul

set LIBDIR=%CD%
git clean -dxf > Nul

cd ..\..\..\Source
git clean -dxf > Nul
set SRCDIR=%CD%

cd ..\Build
set BUILDDIR=%CD%

:: ZLIB
cd %SRCDIR%\zlib128
start "building zlib"     %STARTOPT% %BUILDLIB% libz.lib %LIBDIR%\zlib.lib

:: JPEG
cd %SRCDIR%\jpeg-9b
start "building jpeg"     %STARTOPT% %BUILDLIB% libjpeg.lib  %LIBDIR%\jpeg.lib

:: PNG
cd %SRCDIR%\png-1.6.21
start "building png"      %STARTOPT% %BUILDLIB% libpng.lib %LIBDIR%\png.lib

:: GD
cd %SRCDIR%\gd-2.0.15
start "building gd"       %STARTOPT% call %BUILDLIB% libgd.lib %LIBDIR%\gd.lib

:: GLUT
cd %SRCDIR%\glut-3.7.6
start "building glut"     %STARTOPT% %BUILDLIB% libglutwin.lib %LIBDIR%\glut32.lib

:: GLUI
cd %SRCDIR%\glui_v2_1_beta
start "building glui"     %STARTOPT% %BUILDLIB% libglui.lib %LIBDIR%\glui.lib

:: pthreads
cd %SRCDIR%\pthreads
start "building pthreads" %STARTOPT% %BUILDLIB% libpthreads.lib %LIBDIR%\pthreads.lib

cd %CURDIR%

:start
set finished=1
timeout 1 > Nul
for %%x in ( zlib128 jpeg-9b png-1.6.21 gd-2.0.15  glut-3.7.6 glui_v2_1_beta pthreads ) do (
  cd %SRCDIR%\%%x
  if not exist finished set finished=0
)
if %finished% == 0 goto start

