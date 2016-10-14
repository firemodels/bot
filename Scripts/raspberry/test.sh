#!/bin/bash

# create batch and smokebot queues

qmgr -c 'create queue batch2'
qmgr -c 'set queue batch2 queue_type = execution'
qmgr -c 'set queue batch2 started = true'
qmgr -c 'set queue batch2 enabled = true'
qmgr -c 'set queue batch2 resources_default.walltime = 99:00:00'
qmgr -c 'set queue batch2 resources_default.nodes = 1'

