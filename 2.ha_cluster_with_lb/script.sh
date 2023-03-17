#!/bin/bash

# Array of VM IPs and names
VM_IPS_ARRAY="172.16.16.101 master-03-17-1 master-03-17-1.example.com,172.16.16.102 master-03-17-2 master-03-17-2.example.com"

# Set the Internal Field Separator to comma
IFS=','

# Write the configuration header to the file
echo "balance roundrobin" > haproxy.cfg

# Loop over the array and generate the output
for vm_ips in $VM_IPS_ARRAY
do
  # Split the array element into separate variables
  IFS=' ' read -ra arr <<< "$vm_ips"
  ip="${arr[0]}"
  name="${arr[1]}"
  hostname="${arr[2]}"
  
  # Generate multiple lines for each element of the array
  echo "  server $name" >> haproxy.cfg
  echo "    bind $ip:30100" >> haproxy.cfg
  echo "    mode tcp" >> haproxy.cfg
  echo "    option tcp-check" >> haproxy.cfg
  echo "    tcp-check expect string +OK" >> haproxy.cfg
  echo "    tcp-check send PING\\r\\n" >> haproxy.cfg
  echo "    tcp-check expect string +PONG" >> haproxy.cfg
done
