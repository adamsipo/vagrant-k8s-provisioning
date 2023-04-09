# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["VAGRANT_NO_PARALLEL"] = "yes"

IP_RANGE = "172.16.16."

VAGRANT_BOX = "centos/7"
VAGRANT_BOX_VERSION = "2004.01"

CPUS_MASTER_NODE = 2
CPUS_WORKER_NODE = 2

MEMORY_MASTER_NODE = 2048
MEMORY_WORKER_NODE = 1024

MASTER_NODES_COUNT = 2
WORKER_NODES_COUNT = 2

CLUSTER_NAME = "k8s-3"

MASTER_NODE_NAME = "master"
WORKER_NODE_NAME = "worker"

MASTER_LOAD_BALANCER_NAME = "lb-master"
WORKER_LOAD_BALANCER_NAME = "lb-worker"

MASTER_LOAD_BALANCER_IP = "#{IP_RANGE}#{210}"
WORKER_LOAD_BALANCER_IP = "#{IP_RANGE}#{220}"

IP_MASTER_LIST = (1..MASTER_NODES_COUNT).map do |i|
  "#{IP_RANGE}#{100 + i} #{MASTER_NODE_NAME}-#{i} #{MASTER_NODE_NAME}-#{i}"
end.join(",")

IP_WORKER_LIST = (1..WORKER_NODES_COUNT).map do |i|
  "#{IP_RANGE}#{200 + i} #{WORKER_NODE_NAME}-#{i} #{WORKER_NODE_NAME}-#{i}"
end.join(",")

Vagrant.configure(2) do |config|

  # Kubernetes Master and Worker Nodes
  (1..(MASTER_NODES_COUNT + WORKER_NODES_COUNT)).each do |i|
    node_type = i <= MASTER_NODES_COUNT ? "master" : "worker"
    node_name = node_type == "master" ? MASTER_NODE_NAME : WORKER_NODE_NAME
    node_number = node_type == "master" ? i : i - MASTER_NODES_COUNT
    node_ip = node_type == "master" ? "#{IP_RANGE}#{100 + node_number}" : "#{IP_RANGE}#{200 + node_number}"

    config.vm.define "#{node_name}-#{node_number}-#{CLUSTER_NAME}" do |node|
      node.vm.box = VAGRANT_BOX
      node.vm.box_check_update = false
      node.vm.box_version = VAGRANT_BOX_VERSION
      node.vm.hostname = "#{node_name}-#{node_number}"

      node.vm.network "private_network", ip: node_ip

      node.vm.provider :virtualbox do |v|
        v.name = "#{node_name}-#{node_number}-#{CLUSTER_NAME}"
        v.memory = node_type == "master" ? "#{MEMORY_MASTER_NODE}" : "#{MEMORY_WORKER_NODE}"
        v.cpus = node_type == "master" ? "#{CPUS_MASTER_NODE}" : "#{CPUS_WORKER_NODE}"
        v.customize ["modifyvm", :id, "--groups", "/#{CLUSTER_NAME}"]
      end

      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible_provision/playbooks/main.yaml"
        ansible.verbose = ""
        ansible.extra_vars = {
          node_type: node_type,
          ANSIBLE_STDOUT_CALLBACK: "oneline",
          master_load_balancer_ip: MASTER_LOAD_BALANCER_IP,
          worker_load_balancer_ip: WORKER_LOAD_BALANCER_IP,
          ip_master_list: IP_MASTER_LIST,
          ip_worker_list: IP_WORKER_LIST,
          master_load_balancer_name: MASTER_LOAD_BALANCER_NAME,
          worker_load_balancer_name: WORKER_LOAD_BALANCER_NAME,
          master_node_name: MASTER_NODE_NAME,
          worker_node_name: WORKER_NODE_NAME
        }
        ansible.verbose = "vv"
      end
    end
  end
end
