#!/bin/bash
prog=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lockfile=$SCRIPT_DIR/locks/$prog.lock

echo -n "waiting for $prog to finish - "
while [[  -e $lockfile    ]]; do
   sleep 5
done
echo finished

