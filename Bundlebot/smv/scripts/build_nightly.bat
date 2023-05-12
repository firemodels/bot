@echo off

git clean -dxf
git remote update
git merge origin/master
call smv_bundle.bat %*

