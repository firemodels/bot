@echo off
set GH_REPO=test7_bundles
set GH_OWNER=gforney

:: FDS 7 tet and smokeview 7 test
run_bundlebot -c -R release -F 886e00965 -X FDS-6.8.0 -S d02fd6867 -Y SMV-6.8.0


:: FDS 6.7.9 and smokeview 6.7.21
::set use_only_tags=1
::run_bundlebot -c -R release -X FDS6.7.9 -Y SMV6.7.21

