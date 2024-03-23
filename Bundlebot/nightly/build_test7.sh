#!/bin/bash

# FDS 7 tet and smokeview 7 test

./run_bundlebot -f -c -R release -F 16effce15 -X FDS-6.8.0 -S a60ef42f4 -Y SMV-6.8.0 -o gforney -r test7_bundles >& $HOME/.bundle/build_lnx_release.log



