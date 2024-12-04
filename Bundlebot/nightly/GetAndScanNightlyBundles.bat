@echo off

echo cleaning bundles directory
cd bundles
git clean -dxf > Nul
cd ..

echo downloading Linux and OSX bundles
gh release download FDS_TEST -p FDS*.sh -D bundles  -R github.com/firemodels/test_bundles
echo downloading Windows bundle
gh release download FDS_TEST -p FDS*.exe -D bundles  -R github.com/firemodels/test_bundles
echo downloading Windows .pdf files
gh release download FDS_TEST -p FDS*.pdf -D bundles  -R github.com/firemodels/test_bundles
echo downloading sha1 files
gh release download FDS_TEST -p FDS*.sha1 -D bundles  -R github.com/firemodels/test_bundles

echo.
echo scanning nightly bundles in %BUNDLEDIR%
set BUNDLEDIR=%CD%\bundles
sentinelctl scan_folder -t -i %BUNDLEDIR%