#!/bin/bash

SERVER=raspberrypi

/etc/init.d/torque-mom stop
/etc/init.d/torque-scheduler stop
/etc/init.d/torque-server stop
pbs_server -t create

killall pbs_server

echo $SERVER > /etc/torque/server_name
echo $SERVER > /var/spool/torque/server_priv/acl_svr/acl_hosts
echo root@SERVER > /var/spool/torque/server_priv/acl_svr/operators
echo root@SERVER > /var/spool/torque/server_priv/acl_svr/managers

echo "$SERVER np=4" > /var/spool/torque/server_priv/nodes

echo $SERVER > /var/spool/torque/mom_priv/config

/etc/init.d/torque-server restart
/etc/init.d/torque-scheduler restart
/etc/init.d/torque-mom restart
