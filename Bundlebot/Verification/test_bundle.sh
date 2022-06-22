#!/bin/bash

QFDS=../../../fds/Utilities/qfds.sh
$QFDS -o 1 -p 1  test01a.fds
$QFDS -o 4 -p 1  test01b.fds
$QFDS -o 1 -p 4  test04a.fds
$QFDS -o 2 -p 4  test04b.fds
