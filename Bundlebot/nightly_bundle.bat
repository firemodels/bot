@echo off
set CURDIR=%CD%
call run_bundlebot -c
cd %CURDIR%
echo complete