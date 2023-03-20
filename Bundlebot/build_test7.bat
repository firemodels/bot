@echo off
set GH_REPO=test7_bundles

:: FDS 7 tet and smokeview 7 test
run_bundlebot -c -R release -F 4f017f05f -X FDS7TEST -S dbfdc2afe -Y SMV7TEST


:: FDS 6.7.9 and smokeview 6.7.21
::set use_only_tags=1
::run_bundlebot -c -R release -X FDS6.7.9 -Y SMV6.7.21

