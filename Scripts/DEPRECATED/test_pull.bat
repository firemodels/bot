@echo off
set num=%1
set repoarg=%2
set repo=smv
if "x%repoarg%" == "x" goto endif1
  set repo=%repoarg%
:endif1

cd ..\..\%repo%

git fetch firemodels pull/%1/head:PR_%1
git branch -a

