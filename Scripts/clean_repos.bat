@echo off
set CUR=%CD%
set allrepos=bot cad cfast cor exp fds fig out radcal smv test_bundles

cd ..\..
set repo=%CD%
cd %CUR%

for %%x in ( %allrepos% ) do ( call :clean_repo %%x )

goto eof

:clean_repo
  set reponame=%1
  echo ***cleaning %reponame%
  set repodir=%repo%\%reponame%
  if not exist %repodir% (
     exit /b
  )
  cd %repodir%
  git remote prune origin 1> Nul 2> Nul
  git checkout master     1> Nul 2> Nul
  git clean -dxf          1> Nul 2> Nul
  exit /b

:eof
cd %CUR%