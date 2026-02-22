#!/bin/bash

################################################################################
# Reconnect outside port 8080 to inside 443 for ArgoCD WebGUI
################################################################################

# Exit on error, treat unset vars as errors, print command before executing
set -eu

################################################################################
# ArgoCD WebGUI Setup & Status
################################################################################

# Display default password for admin
echo "Your initial secret for admin is: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
# View status of ArgoCD
kubectl get all -n argocd
# Print command for loggin into argocd
echo -e "************************************************************************************\n\nYou can log into the argocd cli with the following command:\n\nargocd login localhost:8080 --username admin --password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" --insecure\n\n************************************************************************************"
# port-forward the webgui for ArgoCD. Run in background and save PID
kubectl -n argocd port-forward svc/argocd-server 8080:443 > /tmp/argocd-portforward.log 2>&1 &
echo $! > /tmp/argocd-portforward.pid