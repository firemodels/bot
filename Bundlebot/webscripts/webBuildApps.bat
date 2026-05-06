@echo off

if %1 == firebot  cd ..\..\fds\Build\impi_intel_win
if %1 == firebot  start "build fds" cmd /c "call make_fds

if %1 == smokebot set CURDIR=%CD%
if %1 == smokebot cd %CURDIR%\..\..\smv\Build\smokeview\intel_win
if %1 == smokebot start "build smokeview" cmd /c "call make_smokeview"

if %1 == smokebot cd %CURDIR%\..\..\smv\Build\fds2fed\intel_win
if %1 == smokebot start "build smokeview" cmd /c "call make_fds2fed"
