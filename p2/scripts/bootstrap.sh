#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

echo "Running bootstrap.sh"

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Wait for API server to initialize
until sudo k3s kubectl get --raw='/readyz' >/dev/null 2>&1; do
  echo "Waiting for k3s API server..."
  sleep 2
done
echo "k3s API in ready state."