#!/bin/bash

cd ../Firebot

# run firebot and build manuals for FDS6.7.6 release
#./run_firebot.sh -u -c -J -q firebot -x 5064c500c -X FDS6.7.6 -y a2687cda4 -Y SMV6.7.16 -R release -U -w firebot/clone


# run firebot and build manuals for FDS6.7.7 release
./run_firebot.sh -u -c -J -q firebot -x gfe0d4ef38 -X FDS6.7.7 -y dce043cd7 -Y SMV6.7.18 -R release -U -w firebot/clone
