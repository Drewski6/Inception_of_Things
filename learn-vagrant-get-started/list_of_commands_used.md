# List of commands

- Here is a history of the commands I used when doing the vagrant tutorial


## Install Vagrant

```bash
# Initial setup of host
sudo apt update && sudo apt upgrade -y
sudo apt install -y git vim openssh-server virtualbox

# Install Vagrant on host machine
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

## Setup Environment

- Started with the following tutorial.
- https://developer.hashicorp.com/vagrant/tutorials/get-started/setup-project

```bash
# setup working folder
mkdir learn-vagrant-get-started
cd learn-vagrant-get-started

# init vagrant file with ubuntu 24
vagrant init hashicorp-education/ubuntu-24-04 --box-version 0.1.0

```

- Try `vagrant up`

- This might not work the first time. You might need to troubleshoot a few things on the host or on the VM before it'll work. This is what worked for me.

- On host: Need to activate Nested VT-x option, but cant do this from the GUI. You need to run this command to turn it on

```bash
vboxmanage modifyvm <name of VM|IoT> --nested-hw-virt=on 
```

- Back to VM

```bash
vagrant up
```

- If you get an error like below, you might need to change some settings in the VM to allow virtualbox to run.

```bash
There was an error while executing `VBoxManage`, a CLI used by Vagrant
for controlling VirtualBox. The command and stderr is shown below.

Command: ["startvm", "edec36cc-afb6-4775-8908-a01fe7455470", "--type", "headless"]

Stderr: VBoxManage: error: VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_VMX_IN_VMX_ROOT_MODE)
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component ConsoleWrap, interface IConsole
```

- If another virtual machine is being used (like KVM), then you might need to turn this off in order to use VirtualBox
- Run:

```bash
lsmod | grep kvm
```

- if you get something like this:

```bash
kvm_intel             487424  0
kvm                  1425408  1 kvm_intel
irqbypass              12288  1 kvm
```

- then you need to turn these off before vagrant can run
- Turn them off with this:

```bash
sudo rmmod kvm_intel && sudo rmmod kvm
```

- At this point, you can run `vagrant up` once again and see if it works.

- At this point going the virtual box method didn't work, so I'm trying the kvm route.
- I restarted the machine which effectely undid the previous command and now `lsmod  grep kvm` shows this again:

```bash
kvm_intel             487424  0
kvm                  1425408  1 kvm_intel
irqbypass              12288  1 kvm
```

- Now update and install required libraries

```bash
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager dnsmasq-base ebtables iptables bridge-utils
```

- Then this:

```bash
sudo usermod -aG libvirt,kvm $USER
```

- Logout and log back in

- Sanity check. Output should be empty but not an error

```bash
virsh list --all
```

- Try to make a new box for ubuntu

```bash
vagrant box add generic/ubuntu2204 --provider=libvirt
```


## Provision Environment

- https://developer.hashicorp.com/vagrant/tutorials/get-started/provision

```bash

```


## Port forwarding and folder sync

- https://developer.hashicorp.com/vagrant/tutorials/get-started/network-folder-sync

```bash

```


## Milti-machine environments

- https://developer.hashicorp.com/vagrant/tutorials/get-started/multi-machine

```bash

```