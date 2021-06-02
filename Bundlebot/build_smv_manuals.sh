#!/bin/bash

# run smokebot and build manuals for FDS6.7.6/SMV6/7.16 release
cd ../Smokebot
./run_smokebot.sh -c -u -J -q batch3 -m gforney@gmail.com -x 536c429eb -X FDS6.7.6 -y 485e0cd19 -Y SMV6.7.16 -R release -M -U -w smokebot/clone
