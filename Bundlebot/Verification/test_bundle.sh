#!/bin/bash

QFDS=../../../fds/Utilities/Scripts/qfds.sh -j BUN
$QFDS -i -o 1 -p 1  test01a.fds
$QFDS -i -o 4 -p 1  test01b.fds
$QFDS -i -o 1 -p 4  test04a.fds
$QFDS -i -o 2 -p 4  test04b.fds
