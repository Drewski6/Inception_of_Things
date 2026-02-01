#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

SERVER_HOST=dpentlanS
WORKER_HOST=dpentlanSW
SERVER_IP=192.168.56.110
WORKER_IP=192.168.56.111
K3S_TOKEN=K108d19ba3be7833d487b9a64d68a4aaa5413e8a2cede74155d1bdc0d123f6fe8e4::server:036d8fa3a05a4ed1072866bb26b16454

echo "Running bootstrap_worker.sh"

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl

# Install k3s
# curl -sfL https://get.k3s.io | \
#   sudo INSTALL_K3S_VERSION="${K3S_VERSION}" K3S_URL="https://${SERVER_HOST}:6443" K3S_TOKEN="${token}" bash -s - agent --node-name "${WORKER_HOST}"

# Still need to test token. Need to get token from server machine and put in a shared file or scp it over to the worker?

curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -