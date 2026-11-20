@echo off
setlocal
set branch=%1
set repo=%2

if not "x%branch%" == "x" goto endif0
if not "x%repo%"   == "x" goto endif0
  echo Usage: newbranch branch repo
  echo   create a branch in repo repo.
  echo.
  echo   branch - branch to be created
  echo   repo   - repo branch is created in (default: smv)
  exit /b
:endif0


if "x%repo%" == "x" set repo=smv

set CURDIR=%CD%

cd ..\.. || exit /b 1
set GITROOT=%CD%

cd /d "%CURDIR%" || exit /b 1

set repodir=%GITROOT%\%repo%
if exist "%repodir%\." goto endif1
  echo ***error: repo %repodir% does not exist
  exit /b
:endif1

if NOT "x%branch%" == "x" goto endif2
  echo ***error: branch parameter is missing
  exit /b
:endif2

set "have_push_url="
for /f "delims=" %%u in ('git -C "%repodir%" remote get-url --push --all origin') do set "have_push_url=1"
if not defined have_push_url (
  echo ***error: Could not determine the origin push URL for "%repodir%".
  exit /b 1
)
git -C "%repodir%" remote get-url --push --all origin | findstr /i /r /c:"^[a-z][a-z0-9+.-]*://github\.com/firemodels/" /c:"^[a-z][a-z0-9+.-]*://[^/]*@github\.com/firemodels/" /c:"^[^/@][^/@]*@github\.com:firemodels/" /c:"^github\.com:firemodels/" /c:"^[a-z][a-z0-9+.-]*://github\.com:[0-9][0-9]*/firemodels/" /c:"^[a-z][a-z0-9+.-]*://[^/]*@github\.com:[0-9][0-9]*/firemodels/" >nul
if not errorlevel 1 (
  echo WARNING: origin pushes to FireModels on GitHub. To create and publish the branch manually, run:
  echo git -C "%repodir%" checkout -b "%branch%" firemodels/master
  echo git -C "%repodir%" push -u origin "%branch%"
  exit /b 1
)

echo Do you wish to create the branch: %branch% in repo: %repodir% ?
echo Press any key to continue, CTRL c to abort
pause >Nul

cd /d "%repodir%" || exit /b 1
git checkout -b %branch% firemodels/master
git push -u origin %branch%


