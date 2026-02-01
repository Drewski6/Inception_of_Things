#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

SERVER_HOST=dpentlanS
WORKER_HOST=dpentlanSW
SERVER_IP=192.168.56.110
WORKER_IP=192.168.56.111

echo "Running bootstrap_server.sh"

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl

# Install k3s
# curl -sfL https://get.k3s.io | \
#   sudo INSTALL_K3S_VERSION="${K3S_VERSION}" bash - server --node-name "${SERVER_HOST}" --tls-san "${SERVER_IP}" --tls-san "${SERVER_HOST}"

curl -sfL https://get.k3s.io | sh -