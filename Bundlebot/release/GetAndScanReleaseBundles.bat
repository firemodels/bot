@echo off
set TAG=FDS-6.9.1

echo cleaning bundles directory
set CURDIR=%CD%
cd bundles
git clean -dxf > Nul

cd %CURDIR%

echo downloading Linux and OSX bundles
gh release download %TAG% -p FDS*.sh -D bundles  -R github.com/firemodels/fds

echo downloading Windows bundle
gh release download %TAG% -p FDS*.exe -D bundles  -R github.com/firemodels/fds

echo downloading documents
gh release download %TAG% -p FDS*.pdf -D bundles  -R github.com/firemodels/fds

echo.
echo scanning nightly bundles in %BUNDLEDIR%
set BUNDLEDIR=%CD%\bundles
sentinelctl scan_folder -t -i %BUNDLEDIR%
