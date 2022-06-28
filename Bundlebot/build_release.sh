#!/bin/bash

# FDS 6.7.6 and smokeview 6.7.16
# ./run_bundlebot.sh -f -P $HOME/.bundle/bundle_settings.sh -R release -F 5064c500c -X FDS6.7.6 -S 485e0cd19 -Y SMV6.7.16 

# FDS 6.7.7 and smokeview 6.7.18
# ./run_bundlebot.sh -f -P $HOME/.bundle/bundle_settings.sh -R release -F fe0d4ef38 -X FDS6.7.7 -S dce043cd7 -Y SMV6.7.18 

# FDS 6.7.9 and smokeview 6.7.21
# ./run_bundlebot.sh -f -R release -F b81287c1e -X FDS6.7.9 -S 33420d46b -Y SMV6.7.21
export use_only_tags=1
 ./run_bundlebot.sh -f -R release -X FDS6.7.9 -Y SMV6.7.21




