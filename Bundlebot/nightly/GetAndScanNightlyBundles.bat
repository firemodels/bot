@echo on

echo downloading Linux and OSX bundles
gh release download FDS_TEST -p FDS*.sh -D bundles  -R github.com/firemodels/test_bundles
echo downloading Windows bundle
gh release download FDS_TEST -p FDS*.exe -D bundles  -R github.com/firemodels/test_bundles

echo.
echo scanning nightly bundles in %BUNDLEDIR%
set BUNDLEDIR=%CD%\bundles
sentinelctl scan_folder -t -i %BUNDLEDIR%