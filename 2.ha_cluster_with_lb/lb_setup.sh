#!/bin/bash

set -xv

if [ -z "$MASTER_LOAD_BALANCER_IP" ] && [ -z "$WORKER_LOAD_BALANCER_IP" ]; then
  echo "No environment variables set"
  exit 1
fi

# Add entry for VAR1 if set
if [ ! -z "$MASTER_LOAD_BALANCER_IP" ]; then
  IP_VIP=$MASTER_LOAD_BALANCER_IP
fi

# Add entry for VAR2 if set
if [ ! -z "$WORKER_LOAD_BALANCER_IP" ]; then
  IP_VIP=$WORKER_LOAD_BALANCER_IP
fi

# Write the configuration header to the file
cat <<EOF | sudo tee haproxy.cfg > /dev/null 2>&1
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

listen stats  # Listen on localhost:9000
  bind *:9000
  mode http
  stats enable  # Enable stats page
  stats hide-version  # Hide HAProxy version
  stats realm Haproxy\ Statistics  # Title text for popup window
  stats uri /stats  # Stats URI
  stats auth admin:admin  # Authentication credentials

frontend kubernetes-frontend
  bind *:$PORT_VIP
  mode tcp
  option tcplog
  default_backend kubernetes-backend

backend kubernetes-backend
  option httpchk GET /healthz
  http-check expect status 200
  mode tcp
  balance roundrobin
    server master1 172.16.16.201:30100 check
    server worker2 172.16.16.202:30100 check
EOF

IFS=','
# Loop over the array and generate the output
for vm_ips in $VM_IPS
do
  # Split the array element into separate variables
  IFS=' ' read -ra arr <<< "$vm_ips"
  ip="${arr[0]}"
  name="${arr[1]}"
  hostname="${arr[2]}"
  
sudo sed -i "/balance roundrobin/{:a;N;/check$/!ba;s/.*/    server $name $ip:30100 check/}" haproxy.cfg

done

