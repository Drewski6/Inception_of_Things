#!/bin/bash

################################################################################
# Reconnect outside port 8888 to port 8888 inside the cluster
################################################################################

# Exit on error, treat unset vars as errors, print command before executing
set -eu

################################################################################
# Print dev status and initiate port forward rule
################################################################################

# View status of dev namespace
kubectl get all -n dev
# port-forward the app. Run in background and save PID
kubectl -n dev port-forward svc/wil42-app 8888:8888 > /tmp/wil42-portforward.log 2>&1 &
echo $! > /tmp/wil42-portforward.pid