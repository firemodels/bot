#!/bin/bash

# run firebot and build manuals for FDS6.7.6 release
cd ../Firebot
./run_firebot.sh -u -c -J -q firebot -x 5064c500c -X FDS6.7.6 -y a2687cda4 -Y SMV6.7.16 -R release -U -w firebot/clone
