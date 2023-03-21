#!/bin/bash
echo "[TASK 1] Set environment variables"

echo "export IP_MASTER_LIST=\"$IP_MASTER_LIST\"" >> /etc/profile.d/custom_env.sh
echo "export IP_WORKER_LIST=\"$IP_WORKER_LIST\"" >> /etc/profile.d/custom_env.sh
echo "export MASTER_LOAD_BALANCER_IP=\"$MASTER_LOAD_BALANCER_IP\"" >> /etc/profile.d/custom_env.sh
echo "export WORKER_LOAD_BALANCER_IP=\"$WORKER_LOAD_BALANCER_IP\"" >> /etc/profile.d/custom_env.sh
echo "export MASTER_LOAD_BALANCER_NAME=\"$MASTER_LOAD_BALANCER_NAME\"" >> /etc/profile.d/custom_env.sh
echo "export WORKER_LOAD_BALANCER_NAME=\"$WORKER_LOAD_BALANCER_NAME\"" >> /etc/profile.d/custom_env.sh
echo "export MASTER_NODE_NAME=\"$MASTER_NODE_NAME\"" >> /etc/profile.d/custom_env.sh
echo "export WORKER_NODE_NAME=\"$WORKER_NODE_NAME\"" >> /etc/profile.d/custom_env.sh

echo "[TASK 2] Update /etc/hosts file"

IFS=',' read -ra VM_IPS_ARRAY <<< "$IP_MASTER_LIST"
for i in "${VM_IPS_ARRAY[@]}"; do
  echo "$i" >> /etc/hosts
done

IFS=',' read -ra VM_IPS_ARRAY <<< "$IP_WORKER_LIST"
for i in "${VM_IPS_ARRAY[@]}"; do
  echo "$i" >> /etc/hosts
done

if [ -z "$MASTER_LOAD_BALANCER_IP" ] && [ -z "$WORKER_LOAD_BALANCER_IP" ]; then
  echo "No environment variables set"
  exit 1
fi

# Add entry for VAR1 if set
if [ ! -z "$MASTER_LOAD_BALANCER_IP" ]; then
  echo "$MASTER_LOAD_BALANCER_IP $MASTER_LOAD_BALANCER_NAME" >> /etc/hosts
fi

# Add entry for VAR2 if set
if [ ! -z "$WORKER_LOAD_BALANCER_IP" ]; then
  echo "$WORKER_LOAD_BALANCER_IP $WORKER_LOAD_BALANCER_NAME" >> /etc/hosts
fi

