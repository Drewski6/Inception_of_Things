#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

SERVER_HOST=dpentlanS
WORKER_HOST=dpentlanSW
SERVER_IP=192.168.56.110
WORKER_IP=192.168.56.111
K3S_TOKEN=K10da2103fc3d5bd28b67eaba39ab81f82ffe936c2d32527ab1f821a937a7fcc617::server:e22e441fe129ca227a32d0dad03ab639

echo "Running bootstrap_worker.sh"

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl

# Install k3s
curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -