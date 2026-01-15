#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

echo "Running bootstrap.sh"

sudo apt update
sudo apt upgrade -y