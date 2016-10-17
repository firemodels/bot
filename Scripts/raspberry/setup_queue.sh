#!/bin/bash

SERVER=`hostname`

# create batch and smokebot queues

qmgr -c 'create queue batch'
qmgr -c 'set queue batch queue_type = execution'
qmgr -c 'set queue batch started = true'
qmgr -c 'set queue batch enabled = true'
qmgr -c 'set queue batch resources_default.walltime = 99:00:00'
qmgr -c 'set queue batch resources_default.nodes = 1'
qmgr -c 'set server default_queue = batch'

qmgr -c 'create queue smokebot'
qmgr -c 'set queue smokebot queue_type = execution'
qmgr -c 'set queue smokebot started = true'
qmgr -c 'set queue smokebot enabled = true'
qmgr -c 'set queue smokebot resources_default.walltime = 99:00:00'
qmgr -c 'set queue smokebot resources_default.nodes = 1'

# configure submission pool 

qmgr -c 'set server submit_hosts = $SERVER'
qmgr -c 'set server allow_node_submit = true'

