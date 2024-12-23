@echo off
set num=%1
set repoarg=%2
set repo=smv
if "x%repoarg%" == "x" goto endif1
  set repo=%repoarg%
:endif1

set CURDIR=%CD%
cd ..\..\%repo%


git fetch firemodels pull/%1/head:test_%1
git branch -a

