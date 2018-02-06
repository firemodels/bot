#!/bin/bash

SERVER=`hostname`

# create batch and smokebot queues

queue=batch
need=compute
qmgr -c "create queue $queue"
qmgr -c "set queue $queue queue_type = Execution"
qmgr -c "set queue $queue resources_default.neednodes = $need"
qmgr -c "set queue $queue resources_default.nodes = 1"
#qmgr -c 'set queue $queue resources_default.walltime = 99:00:00'
qmgr -c "set queue $queue enabled = True"
qmgr -c "set queue $queue started = True"

queue=smokebot
need=compute
qmgr -c "create queue $queue"
qmgr -c "set queue $queue queue_type = Execution"
qmgr -c "set queue $queue resources_default.neednodes = $need"
qmgr -c "set queue $queue resources_default.nodes = 1"
#qmgr -c 'set queue $queue resources_default.walltime = 99:00:00'
qmgr -c "set queue $queue enabled = True"
qmgr -c "set queue $queue started = True"

# configure submission pool 

qmgr -c 'set server default_queue = batch'
qmgr -c 'set server scheduling = True'
qmgr -c 'set server submit_hosts = submission_mode'
qmgr -c 'set server allow_node_submit = true'

