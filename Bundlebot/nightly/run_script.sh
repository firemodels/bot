#!/bin/bash
prog=$*
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lockfile=$SCRIPT_DIR/locks/$1.lock
touch $lockfile
$prog
rm $lockfile
