@echo off
set opt=%1

if x"%opt%" == x"-h" goto skip1
  echo *** updating bot repo
  git clean -dxf          > Nul 2>&1
  git remote update       > Nul 2>&1
  git merge origin/master > Nul 2>&1
:skip1
call smvbundle.bat %*

