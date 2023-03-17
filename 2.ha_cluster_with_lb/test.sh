#!/bin/bash
echo "[TASK 10] Update /etc/hosts file"

echo "VM_IPS_ARRAY: $VM_IPS"

IFS=',' read -ra VM_IPS_ARRAY <<< "$VM_IPS"
for i in "${VM_IPS_ARRAY[@]}"; do
  echo "$i" >> /etc/hosts
done

if [ -z "$MASTER_LOAD_BALANCER_IP" ] && [ -z "$WORKER_LOAD_BALANCER_IP" ]; then
  echo "No environment variables set"
  exit 1
fi

# Add entry for VAR1 if set
if [ ! -z "$MASTER_LOAD_BALANCER_IP" ]; then
  echo "$MASTER_LOAD_BALANCER_IP lb-master" >> /etc/hosts
fi

# Add entry for VAR2 if set
if [ ! -z "$WORKER_LOAD_BALANCER_IP" ]; then
  echo "$WORKER_LOAD_BALANCER_IP lb-worker" >> /etc/hosts
fi

