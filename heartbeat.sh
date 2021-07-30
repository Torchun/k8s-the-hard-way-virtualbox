#!/bin/bash

apt-get update
apt-get install -y heartbeat

cat >/etc/ha.d/ha.cf <<EOF
debugfile /var/log/ha-debug
logfile /var/log/ha-log
### Facility to use for syslog()/logger (alternative to vlog/debugfile)
logfacility     local0
### keepalive: how many seconds between heartbeats
keepalive 2
### deadtime: seconds-to-declare-host-dead
deadtime 30
### the maximum seconds to wait for other nodes to check in at cluster startup
initdead 120
udpport 694
### Deprecated: determine whether a resource would automatically fail back to its "primary" node
auto_failback off
### Controllers only
ucast $(ip -4 --oneline addr | grep '10\.99\.13\.' | cut -d' ' -f2) 10.99.13.10
ucast $(ip -4 --oneline addr | grep '10\.99\.13\.' | cut -d' ' -f2) 10.99.13.11
ucast $(ip -4 --oneline addr | grep '10\.99\.13\.' | cut -d' ' -f2) 10.99.13.12
### Tell what machines are in the cluster
### node    nodename ...    -- must match uname -n
node    controller-0
node    controller-1
node    controller-2
EOF

cat >/etc/ha.d/haresources <<EOF
### That (Virtual IP) etcd instance will be "main" by default, same configuration on each node.
controller-0 IPaddr::10.99.13.100/24/$(ip -4 --oneline addr | grep '10\.99\.13\.' | cut -d' ' -f2)
EOF

cat >/etc/ha.d/authkeys <<EOF
auth 1
### This is for mutual auth purposes
1 md5 just-for-learning
EOF
chmod 600 /etc/ha.d/authkeys

service heartbeat restart
