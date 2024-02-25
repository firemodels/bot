@echo off
call BUILD_config.bat

set "TITLE=Bundle Test - %BUNDLE_FDS_TA%G/%BUNDLE_FDS_REVISION% - %BUNDLE_SMV_TAG%/%BUNDLE_SMV_REVISION%"
gh release edit %GH_FDS_TAG%  -t %$TITLE% -R github.com/%GH_OWNER%/%GH_REPO%
