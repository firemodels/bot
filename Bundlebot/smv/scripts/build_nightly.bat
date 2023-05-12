@echo off

echo *** updating bot repo
git clean -dxf          > Nul 2>&1
git remote update       > Nul 2>&1
git merge origin/master > Nul 2>&1
call bundle_smv.bat %*

