#!/bin/bash

# set -xv
echo "[TASK 12] Install Loadbalancer components allow ha-proxy in SELinux"

PORT_VIP=10443
hostname=$(hostname)

case "$hostname" in
  master*)
    if [ -z "$MASTER_LOAD_BALANCER_IP" ]; then
      echo "MASTER_LOAD_BALANCER_IP environment variable not set"
      exit 1
    fi
    VM_IPS=$IP_MASTER_LIST
    IP_VIP=$MASTER_LOAD_BALANCER_IP
    VIRTUAL_ROUTER_ID=1
    PORT=6443
    ;;
  worker*)
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
# Global settings
#---------------------------------------------------------------------
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    log                     global
    mode                    tcp
    option                  tcplog
    option                  dontlognull
    retries                 3
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    maxconn                 3000

# Stats page configuration
listen stats
    bind *:9000
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /stats
    stats auth admin:admin

# Frontend configuration
frontend kubernetes-frontend
    bind *:10443
    mode tcp
    default_backend kubernetes-backend

# Backend configuration
backend kubernetes-backend
    mode tcp
    option tcp-check
    option ssl-hello-chk
    balance roundrobin
EOF

cat <<EOF | sudo tee /etc/keepalived/keepalived.conf > /dev/null 2>&1
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 2
  timeout 3
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

systemctl enable --now keepalived haproxy &>/dev/null
systemctl restart keepalived haproxy
systemctl status keepalived haproxy

