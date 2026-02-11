#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

echo "Running bootstrap.sh"

export DEBIAN_FRONTEND=noninteractive

# Adding these options to my apt-get calls because I was having network issues and these options help
APT_OPTS=(
  "-y"
  "-o" "Acquire::Retries=5"
  "-o" "Acquire::https::Timeout=30"
  "-o" "Acquire::http::Timeout=30"
)

# Update packages and install curl, git, and ca-certificates for ssl certs
sudo apt-get update "${APT_OPTS[@]}"
sudo apt-get install "${APT_OPTS[@]}" --no-install-recommends ca-certificates curl # git
sudo update-ca-certificates >/dev/null 2>&1 || true

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Wait for API server to initialize
until sudo k3s kubectl get --raw='/readyz' >/dev/null 2>&1; do
  echo "Waiting for k3s API server..."
  sleep 2
done
echo "k3s API in ready state."

# Apply settings from traefik-values.yaml to the pre-installed kubernetes traefik config.
sudo k3s kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n kube-system create configmap traefik-custom-values --from-file=values.yaml=traefik-values.yaml -o yaml --dry-run=client | sudo kubectl apply -f -

sudo k3s kubectl apply -f ./first-app-service.yaml
sudo k3s kubectl apply -f ./first-app-ingress.yaml

sudo k3s kubectl create deployment first-app --image=paulbouwer/hello-kubernetes:1.10.1