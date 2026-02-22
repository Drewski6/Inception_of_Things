#!/bin/bash

################################################################################
# Kill the process for the kubectl port-forward for the ArgoCD WebGUI
################################################################################

# Exit on error, treat unset vars as errors
set -eu

################################################################################
# Kill the ArgoCD WebGUI port-forward process
################################################################################
kill "$(cat /tmp/argocd-portforward.pid)"