#!/bin/bash
IP_VIP="172.16.16.210"
PORT_VIP="80"

echo "[TASK 11] Install Loadbalancer components allow ha-proxy in SELinux"
sudo yum install -y keepalived > /dev/null 2>&1
sudo yum install -y haproxy > /dev/null 2>&1

cat <<EOF | sudo tee /etc/keepalived/check_apiserver.sh > /dev/null 2>&1
#!/bin/sh

errorExit() {
  echo "*** $@" 1>&2
  exit 1
}

curl --silent --max-time 2 --insecure http://localhost:$PORT_VIP/ -o /dev/null || errorExit "Error GET http://localhost:$PORT_VIP/"
if ip addr | grep -q $IP_VIP; then
  curl --silent --max-time 2 --insecure http://$IP_VIP:$PORT_VIP/ -o /dev/null || errorExit "Error GET http://$IP_VIP:$PORT_VIP/"
fi
EOF

sudo chmod +x /etc/keepalived/check_apiserver.sh

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
    virtual_router_id 2
    priority 100
    advert_int 5
    authentication {
        auth_type PASS
        auth_pass mysecret_worker
    }
    virtual_ipaddress {
        $IP_VIP
    }
    track_script {
        check_apiserver
    }
}
EOF

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
  balance roundrobin
    server worker1 172.16.16.201:30100 check
    server worker2 172.16.16.202:30100 check
EOF

systemctl start keepalived >/dev/null 2>&1
sudo systemctl enable keepalived >/dev/null 2>&1

systemctl start haproxy >/dev/null 2>&1
sudo systemctl enable haproxy >/dev/null 2>&1

sudo systemctl restart keepalived haproxy >/dev/null 2>&1
