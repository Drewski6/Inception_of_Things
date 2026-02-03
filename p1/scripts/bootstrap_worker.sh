#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

SERVER_HOST=dpentlanS
WORKER_HOST=dpentlanSW
SERVER_IP=192.168.56.110
WORKER_IP=192.168.56.111
TOKEN_DST_DIR="/home/vagrant/shared"
TOKEN_DST="${TOKEN_DST_DIR}/token"
K3S_TOKEN=""

echo "Running bootstrap_worker.sh"

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl

until ssh -i /home/vagrant/.ssh/k3s_bootstrap_ed25519 -o StrictHostKeyChecking=no -o ConnectTimeout=2 vagrant@"$SERVER_IP" "sudo test -s $TOKEN_DST"; do
  echo "waiting for server token..."
  sleep 2
done

K3S_TOKEN="$(ssh -i /home/vagrant/.ssh/k3s_bootstrap_ed25519 -o StrictHostKeyChecking=no -o ConnectTimeout=2 vagrant@"$SERVER_IP" "sudo cat $TOKEN_DST")"

# Install k3s
curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -