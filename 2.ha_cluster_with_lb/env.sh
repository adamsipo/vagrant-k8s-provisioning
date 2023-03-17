#!/bin/bash
echo "[TASK 1] Set environment variables"
echo "export IP_MASTER_LIST=\"$IP_MASTER_LIST\"" >> /etc/profile.d/custom_env.sh
echo "export IP_WORKER_LIST=\"$IP_WORKER_LIST\"" >> /etc/profile.d/custom_env.sh
echo "export MASTER_LOAD_BALANCER_IP=\"$MASTER_LOAD_BALANCER_IP\"" >> /etc/profile.d/custom_env.sh
echo "export WORKER_LOAD_BALANCER_IP=\"$WORKER_LOAD_BALANCER_IP\"" >> /etc/profile.d/custom_env.sh
echo "export MASTER_LOAD_BALANCER_NAME=\"$MASTER_LOAD_BALANCER_NAME\"" >> /etc/profile.d/custom_env.sh
echo "export WORKER_LOAD_BALANCER_NAME=\"$WORKER_LOAD_BALANCER_NAME\"" >> /etc/profile.d/custom_env.sh



