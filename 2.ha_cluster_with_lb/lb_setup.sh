#!/bin/bash

# set -xv

PORT_VIP=10443
hostname=$(hostname)

case "$hostname" in
  *master*)
    if [ -z "$MASTER_LOAD_BALANCER_IP" ]; then
      echo "MASTER_LOAD_BALANCER_IP environment variable not set"
      exit 1
    fi
    VM_IPS=$IP_MASTER_LIST
    IP_VIP=$MASTER_LOAD_BALANCER_IP
    VIRTUAL_ROUTER_ID=1
    PORT=6443
    ;;
  *worker*)
    if [ -z "$WORKER_LOAD_BALANCER_IP" ]; then
      echo "WORKER_LOAD_BALANCER_IP environment variable not set"
      exit 1
    fi
    VM_IPS=$IP_WORKER_LIST
    IP_VIP=$WORKER_LOAD_BALANCER_IP
    VIRTUAL_ROUTER_ID=2
    PORT=30100
    ;;
  *)
    echo "Unknown hostname: $hostname"
    exit 1
    ;;
esac

echo "[TASK 11] Install Loadbalancer components allow ha-proxy in SELinux"
sudo yum install -y keepalived > /dev/null 2>&1
sudo yum install -y haproxy > /dev/null 2>&1

cat <<EOF | sudo tee -a /etc/keepalived/check_apiserver.sh > /dev/null 2>&1
#!/bin/sh

errorExit() {
  echo "*** $@" 1>&2
  exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q $IP_VIP; then
  curl --silent --max-time 2 --insecure https://$IP_VIP:$PORT_VIP/ -o /dev/null || errorExit "Error GET https://$IP_VIP:$PORT_VIP/"
fi
EOF

sudo chmod +x /etc/keepalived/check_apiserver.sh

# Write the configuration header to the file
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg > /dev/null 2>&1
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
  option ssl-hello-chk
  balance roundrobin
EOF

cat <<EOF | sudo tee /etc/keepalived/keepalived.conf > /dev/null 2>&1
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  timeout 10
  fall 5
  rise 2
  weight -2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth1
    virtual_router_id $VIRTUAL_ROUTER_ID
    priority 100
    advert_int 5
    authentication {
        auth_type PASS
        auth_pass mysecret
    }
    virtual_ipaddress {
        $IP_VIP
    }
    track_script {
        check_apiserver
    }
}
EOF

# Set the Internal Field Separator to comma
IFS=','

# Loop over the array and generate the output
for vm_ips in $VM_IPS
do
  # Split the array element into separate variables
  IFS=' ' read -ra arr <<< "$vm_ips"
  ip="${arr[0]}"
  name="${arr[1]}"
  hostname="${arr[2]}"

  # Add config lines to haprox.cfg
  sudo sed -i "/balance roundrobin/a \    server $name $ip:$PORT check" "/etc/haproxy/haproxy.cfg"
done

systemctl enable --now keepalived haproxy >/dev/null 2>&1
