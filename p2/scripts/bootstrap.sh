#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

echo "Running bootstrap.sh"

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl git

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Wait for API server to initialize
until sudo k3s kubectl get --raw='/readyz' >/dev/null 2>&1; do
  echo "Waiting for k3s API server..."
  sleep 2
done
echo "k3s API in ready state."

# Install helm (kubernetes package manager) directly rather than install script. Had issues with install script from helm docs.
# VER="v4.1.0"
# ARCH="amd64"
# OS="linux"
# URL="https://get.helm.sh/helm-${VER}-${OS}-${ARCH}.tar.gz"

# curl -fL --http1.1 --retry 20 --retry-all-errors --connect-timeout 20 --max-time 900 \
#   -o /tmp/helm.tgz "$URL"
# tar -xzf /tmp/helm.tgz -C /tmp
# sudo install -m 0755 /tmp/${OS}-${ARCH}/helm /usr/local/bin/helm
# helm version

# Install traefik (Ingress Controller) using helm
# helm repo add traefik https://traefik.github.io/charts
# sudo elm --kubeconfig /etc/rancher/k3s/k3s.yaml install traefik traefik/traefik -f traefik-values.yaml # --wait
# sudo helm --kubeconfig /etc/rancher/k3s/k3s.yaml list -A
# sudo helm --kubeconfig /etc/rancher/k3s/k3s.yaml status traefik