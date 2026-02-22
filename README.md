# Inception_of_Things

- This is my Inception of Things project. Here, I'm documenting the steps I took to install all the necessary software on my host and inside the VM.
- Specifically, these are the commands I used in the terminal or in Virtual Box to set things up.

## Part 1

### Create VM in Virtual Box

- You know how to do this. I made a small ubuntu desktop VM.

### Possible Host Machine Issue

- If you get the error where the OS doesnt want to run any VMs because another hypervisor is using VT-x (this most commonly happens when I restart Ubuntu), use this command:

```bash
sudo rmmod kvm_intel && sudo rmmod kvm
```

### Starting VM

- Enable portforwarding in Virtual Box on the host with settings:

Name   | Protocol | Host IP   | Host Port | Guest IP | Guest Port
-------|----------|-----------|-----------|----------|-----------
Rule 1 | TCP      | 127.0.0.1 | 2233      | [Blank]  | 22        

- SSH into VM using VS Code (if you want).

### Setup Commands inside VM

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install openssh-server git
ssh-keygen -t ed25519 -C "myemailaddress@example.com"
nano ~/.ssh/authorized_keys # Add public ssh key of client.
git clone <IoT git repo link>
```

- Take a snapshot of initial setup

### Install Vagrant

- Download vagrant package

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

- Snapshot after install vagrant

- From this point, I'm going off chatgpt rather than vagrant tutorial because I cant use virtualbox as a provider like in the tutorial

- Install required system packages

```bash
sudo apt update
sudo apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  libvirt-dev \
  virt-manager \
  bridge-utils \
  ruby-dev \
  build-essential
```

- Enable and verify libvirt

```bash
sudo systemctl enable --now libvirtd
virsh list --all

# expected output #
#  Id   Name   State
# --------------------
```

- Add your user to the required groups

```bash
sudo usermod -aG libvirt,kvm $USER
```

- Install the KVM Provider plugin for vagrant

```bash
vagrant plugin install vagrant-libvirt

vagrant plugin list # confirm plugin was successfully installed
```

- Initialize a KVM-backed vagrant box (using official Ubuntu box)
  - Make sure you're inside the correct directory. Vagrant file will be created in current working directory.

```bash
vagrant init generic/ubuntu2404
```

- Edit the Vagrantfile to force KVM/libvirt

```Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2404" # will change this to the latest stable version available

  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
end
```

- Start the VM with KVM

```bash
vagrant up --provider=libvirt
```

- Got this error

```bash
Error while connecting to Libvirt: Error making a connection to libvirt URI qemu:///system:
Call to virConnectOpen failed: Failed to connect socket to '/var/run/libvirt/libvirt-sock': Permission denied
```

- And when running `egrep -c '(vmx|svm)' /proc/cpuinfo` i got `0` which indicates that vitualization is not setup yet. 

- Take a snapshot before troubleshooting

- Restarted the VM and got this error

```bash
The box 'generic/ubuntu2404' could not be found or could not be accessed in the remote catalog. 
If this is a private box on the HashiCorp Vagrant Public Registry, please verify 
you're logged in via `vagrant cloud auth login`. Also, please double-check the name. 
The expanded URL and error message are shown below:

URL: ["https://vagrantcloud.com/generic/ubuntu2404"]
Error: The requested URL returned error: 404
```
- Changed the box version to `generic/ubuntu2204`

- Successfully found and Downloaded the box.

- Added box version number to Vagrantfile

```Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = "4.3.12"
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 2048
    libvirt.cpus = 2
  end
end
```

- When download completed, got this error:

```bash
Error while creating domain: Error saving the server: Call to virDomainDefineXML failed: invalid argument: could not get preferred machine for /usr/bin/qemu-system-x86_64 type=kvm
```

- Ran the following diagnostic Commands

```bash
# 1) Are you in a VM / WSL / container?
systemd-detect-virt

# output
oracle # shows I'm in a virtual machine

# 2) Do you have a KVM device node?
ls -l /dev/kvm

# output 
ls: cannot access '/dev/kvm': No such file or directory # shows that how kvm_* modules are loaded

# 3) Are the KVM kernel modules loaded?
lsmod | egrep 'kvm|kvm_intel|kvm_amd'
# output
# no output shows that kvm is not loaded

# 4) Quick KVM usability test (Ubuntu package)
sudo apt install -y cpu-checker
kvm-ok
# output
INFO: Your CPU does not support KVM extensions
INFO: For more detailed results, you should run this as root
HINT:   sudo /usr/sbin/kvm-ok
# shows that the kvm wont work inside this vm at this time.
```

- Shut down vm and change settings in virtual box
  - Check the box `Enable Nested VT-x/AMD-V`
  - If that check box is grayed out, run this on the host machine

```bash
VBoxManage modifyvm "IoT" --nested-hw-virt on
```

- Boot up the VM again

- Re run diagnostic commands

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
# output
8

ls -l /dev/kvm
# output
crw-rw----+ 1 root kvm 10, 232 Dec 16 18:01 /dev/kvm

sudo /usr/sbin/kvm-ok
# output
[sudo] password for ********: 
INFO: /dev/kvm exists
KVM acceleration can be used
```

- Diagnostic command outputs look good. Re running `vagrant up --provider=libvirt`

- Got this error:

```bash
Volume for domain is already created. Please run 'vagrant destroy' first.
```

- Running `vagrant destroy` then running above `vagrant up` command again

- Success! here is the success output:

```bash
vagrant up --provider=libvirt
Bringing machine 'default' up with 'libvirt' provider...
==> default: Checking if box 'generic/ubuntu2204' version '4.3.12' is up to date...
[fog][WARNING] Unrecognized arguments: libvirt_ip_command
==> default: Creating image (snapshot of base box volume).
==> default: Creating domain with the following settings...
==> default:  -- Name:              test-vagrant-kvm_default
==> default:  -- Description:       Source: /home/dpentlan/Inception_of_Things/test-vagrant-kvm/Vagrantfile
==> default:  -- Domain type:       kvm
==> default:  -- Cpus:              2
==> default:  -- Feature:           acpi
==> default:  -- Feature:           apic
==> default:  -- Feature:           pae
==> default:  -- Clock offset:      utc
==> default:  -- Memory:            2048M
==> default:  -- Base box:          generic/ubuntu2204
==> default:  -- Storage pool:      default
==> default:  -- Image(vda):        /var/lib/libvirt/images/test-vagrant-kvm_default.img, virtio, 128G
==> default:  -- Disk driver opts:  cache='default'
==> default:  -- Graphics Type:     vnc
==> default:  -- Video Type:        cirrus
==> default:  -- Video VRAM:        256
==> default:  -- Video 3D accel:    false
==> default:  -- Keymap:            en-us
==> default:  -- TPM Backend:       passthrough
==> default:  -- INPUT:             type=mouse, bus=ps2
==> default: Creating shared folders metadata...
==> default: Starting domain.
==> default: Domain launching with graphics connection settings...
==> default:  -- Graphics Port:      5900
==> default:  -- Graphics IP:        127.0.0.1
==> default:  -- Graphics Password:  Not defined
==> default:  -- Graphics Websocket: 5700
==> default: Waiting for domain to get an IP address...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 192.168.121.179:22
    default: SSH username: vagrant
    default: SSH auth method: private key
    default: 
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default: 
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
```

- Take a snapshot!

- Now you can use `vagrant ssh` to see if you can ssh into your new machine.

- Confirm the machine version and info with this command:

```bash
lsb_release -a
# output
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.3 LTS
Release:        22.04
Codename:       jammy
```

- Use the `logout` command to logout.

- At this point, I've been following a hybrid tutorial of the official vagrant tutorial and some from chatgpt (because my setup was different from the one in the tutorial). However, with a running machine, I can pick up from the tutorial where a virtual machine is successfully installed:

- Here: https://developer.hashicorp.com/vagrant/tutorials/get-started/setup-project#manage-the-environment-lifecycle


### Configuring Vagrant via the Vagrantfile

1. I defined 2 boxes with the appropriate names in the Vagrantfile

2. I added a network for each of the VMs following the suggested setup from the subject

3. I created the provider configuration also following the subject.
  - kvm driver because that's what my computer wanted (couldn't run nested VirtualBox machines).
  - 1 cpu and 512 MB of memory

4. I created 2 provisioners
  - One is an inline shell command
  - The other is a file on the host called bootstrap.sh in the scripts folder
  - These are run in order from top to bottom in the Vagrantfile so you can organize how you want your provisioning to work.

  - Read more on provisioning here: https://developer.hashicorp.com/vagrant/docs/provisioning/shell

  - 2 Examples for future reference:

```Vagrantfile
control.vm.provision "shell", inline: <<-SHELL
  echo "This is an inline shell command!"
  sudo apt update
  sudo apt upgrade -y
SHELL
```

```Vagrantfile
control.vm.provision "shell", path: "scripts/bootstrap.sh"
```


### Installing Kubernetes

1. Curl the install scripts (skip this step)

```sh
curl -sfL https://get.k3s.io | sh - 
sudo k3s kubectl get node 
```

- I'm realizing the example in the subject says to run these from inside the vagrant VMs. I don't know if it *cant* be run in the host VM, but I mistakenly installed it there first.

- Uninstalled k3s on my Ubuntu VM (the host for the vagrant VMs) using this command: `sudo /usr/local/bin/k3s-uninstall.sh`

1. (Again) Curl the install scripts inside the vagrant VMs

- Used the above `curl` command inside both containers and I have a feeling this was not the right setup. I belive this makes 2 master node. I'll revisit this a little later.

- Looks like to connect the server and worker, there will be some more involved setup.
  - I should consider doing this manually at first and making a script to automate.
  - The process will be different for both the server and the worker.

- Server gets the basic command from the kubernetes docs
  
```sh
curl -sfL https://get.k3s.io | sh -
```

- Worker gets a slightly different command (also from docs) but for setting up the agent

```sh
curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -
```

2. Set up the networking

- After this, I configured the networking settings in the `Vagrantfile`.
- I also added some other provisioning steps
- Vagrantfile now looks like this.

```Vagrantfile
Vagrant.configure("2") do |config|

  config.vm.box = "generic/ubuntu2310"
  config.vm.box_version = "4.3.12"

  config.vm.define "dpentlanS" do |control|
    control.vm.hostname = "dpentlanS"
    control.vm.network "private_network", ip: "192.168.56.110"
    control.vm.provider :libvirt do |libvirt|
      libvirt.driver = "kvm"
      libvirt.memory = 1024 # may need to lower to 512 for school computers
      libvirt.cpus = 2 # may need to lower to 1 for school computers
    end
    control.vm.synced_folder "./confs/shared", "/vagrant", type: "rsync"
    control.vm.provision "file", 
      source: "confs/k3s-config-server.yaml",
      destination: "/home/vagrant/k3s-config.yaml"
    control.vm.provision "shell", inline: <<-SHELL
      set -eux
      sudo mkdir -p /etc/rancher/k3s
      sudo mv /home/vagrant/k3s-config.yaml /etc/rancher/k3s/config.yaml
      sudo chown root:root /etc/rancher/k3s/config.yaml
      sudo chmod 644 /etc/rancher/k3s/config.yaml
    SHELL
    control.vm.provision "shell", path: "scripts/bootstrap_server.sh"
  end

  config.vm.define "dpentlanSW" do |control|
    control.vm.hostname = "dpentlanSW"
    control.vm.network "private_network", ip: "192.168.56.111"
    control.vm.provider :libvirt do |libvirt|
      libvirt.driver = "kvm"
      libvirt.memory = 1024 # may need to lower to 512 for school computers
      libvirt.cpus = 2 # may need to lower to 1 for school computers
    end
    control.vm.synced_folder "./confs/shared", "/vagrant", type: "rsync"
    control.vm.provision "file", 
      source: "confs/k3s-config-worker.yaml",
      destination: "/home/vagrant/k3s-config.yaml"
    control.vm.provision "shell", inline: <<-SHELL
      set -eux
      sudo mkdir -p /etc/rancher/k3s
      sudo mv /home/vagrant/k3s-config.yaml /etc/rancher/k3s/config.yaml
      sudo chown root:root /etc/rancher/k3s/config.yaml
      sudo chmod 644 /etc/rancher/k3s/config.yaml
    SHELL
    control.vm.provision "shell", path: "scripts/bootstrap_worker.sh"
  end
end
```

3. Synchronize the startups

- At this point, if you start the server first with `vagrant up dpentlanS` and then ssh into the server with `vagrant ssh dpentlanS` then you can cat the node token with `sudo cat /var/lib/rancher/k3s/server/node-token` and put that token into the setup script for the worker (dpentlanSW). and then run `vagrant up dpentlanSW` and the worker will connect to the server corrctly. You can also verify this from the server by running `sudo k3s kubectl get nodes -o wide` from inside the server node (`vagrant ssh dpentlanS` from the host) and this will show both the server and worker working correctly.
- However, we need to automate this step.

- Probably will use ssh so the workers can access the server and get the token

- Used this command to generate the keys in my project

```bash
ssh-keygen -t ed25519 -f confs/ssh/k3s_bootstrap_ed25519 -N "" -C "k3s-bootstrap"
```

  A. Server Portion:

- Then we copy the public key into the server during provisioning. 

```Vagrantfile
control.vm.provision "file",
  source: "confs/ssh/k3s_bootstrap_ed25519.pub",
  destination: "/home/vagrant/k3s_bootstrap_ed25519.pub"
```

- We take that copied file's contents (the authroized key for the worker) and put it in the server's authorized_keys file (also in the provisioning step)

```bash
# copy ssh pub into authorized_keys and delete
cat /home/vagrant/k3s_bootstrap_ed25519.pub | tee -a /home/vagrant/.ssh/authorized_keys > /dev/null
rm -f /home/vagrant/k3s_bootstrap_ed25519.pub
```

 B. Worker Portion

- Add the ssh key during provisioning

```Vagrantfile
control.vm.provision "file",
  source: "confs/ssh/k3s_bootstrap_ed25519",
  destination: "/home/vagrant/k3s_bootstrap_ed25519"
```

- and in the script portion of the provisioning.

```bash
# move ssh key into .ssh folder
mv /home/vagrant/k3s_bootstrap_ed25519 /home/vagrant/.ssh/k3s_bootstrap_ed25519
```

- Adding a loop that attempts the ssh connection and looks for the token file in the worker script

```bash
until ssh -i /home/vagrant/.ssh/k3s_bootstrap_ed25519 -o StrictHostKeyChecking=no -o ConnectTimeout=2 vagrant@"$SERVER_IP" "sudo test -s $TOKEN_DST"; do
  echo "waiting for server token..."
  sleep 2
done

K3S_TOKEN="$(ssh -i /home/vagrant/.ssh/k3s_bootstrap_ed25519 -o StrictHostKeyChecking=no -o ConnectTimeout=2 vagrant@"$SERVER_IP" "sudo cat $TOKEN_DST")"
```

- Server and worker scripts now orchestrate the token file transfer via ssh.
  - I'll copy paste my Vagrantfile and worker and server scripts here so you can see them.

```Vagrantfile
Vagrant.configure("2") do |config|

  config.vm.box = "generic/ubuntu2310"
  config.vm.box_version = "4.3.12"

  config.vm.define "dpentlanS" do |control|
    control.vm.hostname = "dpentlanS"
    control.vm.network "private_network", ip: "192.168.56.110"
    control.vm.provider :libvirt do |libvirt|
      libvirt.driver = "kvm"
      libvirt.memory = 1024 # may need to lower to 512 for school computers
      libvirt.cpus = 2 # may need to lower to 1 for school computers
    end
    control.vm.provision "file", 
      source: "confs/k3s-config-server.yaml",
      destination: "/home/vagrant/k3s-config.yaml"
    control.vm.provision "file",
      source: "confs/ssh/k3s_bootstrap_ed25519.pub",
      destination: "/home/vagrant/k3s_bootstrap_ed25519.pub"
    control.vm.provision "shell", inline: <<-SHELL
      set -eux
      # move k3s config file and give correct permissions
      sudo mkdir -p /etc/rancher/k3s
      sudo mv /home/vagrant/k3s-config.yaml /etc/rancher/k3s/config.yaml
      sudo chown root:root /etc/rancher/k3s/config.yaml
      sudo chmod 644 /etc/rancher/k3s/config.yaml
      # copy ssh pub into authorized_keys and delete
      cat /home/vagrant/k3s_bootstrap_ed25519.pub | tee -a /home/vagrant/.ssh/authorized_keys > /dev/null
      rm -f /home/vagrant/k3s_bootstrap_ed25519.pub
    SHELL
    control.vm.provision "shell", path: "scripts/bootstrap_server.sh"
  end

  config.vm.define "dpentlanSW" do |control|
    control.vm.hostname = "dpentlanSW"
    control.vm.network "private_network", ip: "192.168.56.111"
    control.vm.provider :libvirt do |libvirt|
      libvirt.driver = "kvm"
      libvirt.memory = 1024 # may need to lower to 512 for school computers
      libvirt.cpus = 2 # may need to lower to 1 for school computers
    end
    control.vm.provision "file", 
      source: "confs/k3s-config-worker.yaml",
      destination: "/home/vagrant/k3s-config.yaml"
    control.vm.provision "file",
      source: "confs/ssh/k3s_bootstrap_ed25519",
      destination: "/home/vagrant/k3s_bootstrap_ed25519"
    control.vm.provision "shell", inline: <<-SHELL
      set -eux
      sudo mkdir -p /etc/rancher/k3s
      sudo mv /home/vagrant/k3s-config.yaml /etc/rancher/k3s/config.yaml
      sudo chown root:root /etc/rancher/k3s/config.yaml
      sudo chmod 644 /etc/rancher/k3s/config.yaml
      # move ssh key into .ssh folder
      mv /home/vagrant/k3s_bootstrap_ed25519 /home/vagrant/.ssh/k3s_bootstrap_ed25519
    SHELL
    control.vm.provision "shell", path: "scripts/bootstrap_worker.sh"
  end

end
```

- Server script

```bash
#!/bin/bash

set -ux
# e: exit the script when a command returns an error. 
# u: treat unset variables as errors. 
# x: print the command to the terminal before executing.

SERVER_HOST=dpentlanS
WORKER_HOST=dpentlanSW
SERVER_IP=192.168.56.110
WORKER_IP=192.168.56.111
TOKEN_SRC="/var/lib/rancher/k3s/server/node-token"
TOKEN_DST_DIR="/home/vagrant/shared"
TOKEN_DST="${TOKEN_DST_DIR}/token"

echo "Running bootstrap_server.sh"

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Create token file and dir
mkdir -p "$TOKEN_DST_DIR"
touch "$TOKEN_DST"

# Wait for token source file to be generated by k3s
until sudo test -s "$TOKEN_SRC"; do
  echo "Waiting for k3s token..."
  sleep 1
done
echo "k3s token generated."

# Wait for API server to initialize
until sudo k3s kubectl get --raw='/readyz' >/dev/null 2>&1; do
  echo "Waiting for k3s API server..."
  sleep 2
done
echo "k3s API in ready state."

# Copy token to a destination file for access via ssh.
sudo cat "$TOKEN_SRC" | tee "$TOKEN_DST" > /dev/null
sudo chmod 644 "$TOKEN_DST"

```

- Worker script

```bash
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

```

- Part 1 is finished!

## Part 2

### Setting up VM

- Setup a basic Vagrantfile using a lot of the same settings from part 1. Just removed stuff I didn't need. I also changed it to a different box. Now I'm using debian/trixie64 so that I'm obeying the "Latest Stable Version" stipulation in the subject. I'll test with this part and maybe go back to part 1 and update the box there as well as long as I don't encounter too many problems. 

- Box here: https://portal.cloud.hashicorp.com/vagrant/discover/debian/trixie64
- Proof it's the latest stable version: https://www.debian.org/releases/

### Setting up a deployment

- The smallest unit for this part is the deployment. I'll need to create a deployment first so that I can work on accessing it via a reverse proxy (next step).

- I'm using an image off of dockerhub called hello-kubernetes which I can use to prove that my deployment works and is accessible.

```bash
sudo k3s kubectl create deployment first-app --image=paulbouwer/hello-kubernetes:1.10.1
```

- Verify this works with:
  - Should say 1/1 under READY

```bash
sudo k3s kubectl get pods
```

- Normally services can be used to expose pods to so that other apps can communicate with them. You can view the services with this command:

```bash
sudo k3s kubectl get services
```

- By default you should see 1 service which is the default kubernetes service.

- Now our first deployment is created. Now we need to set up a basic ingress controller so we can access its contents.

- k3s has traefik and helm installed by default. We can use these to configure an ingress controller.
- Helm is a kubernetes package manager.
- traefik is basically a reverse proxy that has lots of configuration and plays nicely with kubernetes.

- First we need to make our traefik configuration. We can do this by createing a yaml file with our config.

```yaml
# traefik-values.yaml
ingressRoute:
  dashboard:
    enabled: true
    matchRule: Host(`dashboard.localhost`)
    entryPoints:
      - web
providers:
  kubernetesGateway:
    enabled: false
gateway:
  listeners:
    web:
      namespacePolicy:
        from: All
```

- Next we need to include this in our Vagrantfile as a file to copy over.

```Vagrantfile
control.vm.provision "file", 
  source: "confs/traefik-values.yaml",
  destination: "/home/vagrant/traefik-values.yaml"
```

- Now we need to apply these settings to k3s.

```bash
sudo k3s kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml -n kube-system create configmap traefik-custom-values --from-file=values.yaml=traefik-values
.yaml   -o yaml --dry-run=client | sudo kubectl apply -f -
```

- This command is a bit complex so I can break it down:
  - `sudo k3s kubectl` - uses the kubernetes CLI
  - `--kubeconfig /etc/rancher/k3s/k3s.yaml ` - tells the cli which kubernetes server we want to edit
  - `-n kube-system` - defines which namespace we're dealing with
  - `create configmap traefik-custom-values` - Creates a configmap in kubernetes called traefik-custom-values. A configmap is a key value store for non-secret configuration.
  - `--from-file=values.yaml=traefik-values.yaml` - adds a key to the configmap from a file
    - Left side `values.yaml` - the name inside the configmap
    - Right side `traefik-values.yaml` - the name of the local file to be used.
  - `-o yaml` - generates an output in the form of an yaml file
  - `--dry-run=client` - Doesnt actually apply the changes, just prints them to stdout
  - `|` - pipe
  - `sudo kubectl apply -f -` - reads from stdin what to apply to the current kubernetes cluster.

- With all of this, we are taking the traefik-values.yaml file and we are adding it to the k3s.yaml config for our current cluster.
  - This seems like a round about way of doing it, but this is the best way to apply changes to our cluster's internal ingress controller

- At this point we have a deployment, and our traefik ingress controller is initialized and we have a basic config in it which we can update later.

- Now we need a ClusterIP Service object that will allow us to open up our deployment to traefik

- [come back and finish the explanation]

## Part 3

### Install script

- Unlike the previous two parts, this one requires us to install tools directly on the machine rather than in a Vagrant VM.

- The subject requires us to install several pieces of software directly to our machine.

- Install Docker:

```bash
set -eux

# Install Docker (from Docker docs)
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

# Add Docker's official GPG key:
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Update again in case anything changed
sudo apt-get update -y

# Install the latest version of Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify that Docker is running
sleep 5
sudo systemctl --no-pager status docker
```

- Now we need to install k3d using the k3d install script

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

- We should get some success text printed to the terminal.

- Now we can use the `k3d` command.

```bash
k3d --help # to see some simple help message
```

- Now we install the kubectl system so that we can communicate with our cluster via cli

```bash
################################################################################
# Install kubectl on local machine (for interacting with k3d cluster)
################################################################################

# Download Binary
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# Download checksum
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
# Validate download
sha256sum --check <(awk '{print $1"  kubectl"}' kubectl.sha256)
rm -f kubectl.sha256
# Install Binary
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# Verify install is working
kubectl version --client --output=yaml
rm -f kubectl
```

- NOTE: I used this tutorial for a bit of the setup: https://www.youtube.com/watch?v=ErhVmAEOUBM

- Next we needed to create a new cluster, and install ArgoCD

```bash
################################################################################
# Create a cluster using k3d
################################################################################

# Create the cluster
k3d cluster create
# Verify
k3d cluster list
# Take the config from the newly created cluster and put it in our current users home and use it as the default context
k3d kubeconfig merge k3s-default --kubeconfig-merge-default
kubectl config use-context k3d-k3s-default
# Set config to be owned by user
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube
# Verify nodes are reachable
kubectl get nodes

################################################################################
# Install ArgoCD & CLI
################################################################################

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
# Wait for argocd to spin up
kubectl -n argocd get pods -w
# Display default password for admin
echo "Your initial secret for admin is: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
# port-forward the webgui for ArgoCD. Run in background and save PID
kubectl -n argocd port-forward svc/argocd-server 8080:443 > /tmp/argocd-portforward.log 2>&1 &
echo $! > /tmp/argocd-portforward.pid
```

- The comments here explain pretty much every command

- This script ended up being pretty easy to create. Mostly, I copy pasted from the various tools setup pages in their docs (ie. Docker docs explains how to install docker, k3d docs shows how to install, etc)
- There was a fair bit of testing as I created this script. I took a snapshot of the VM before installing anything, then created the script. To test, I ran the script once, saw the outcome, adding git commits as I went. If I didn't like the outcome, I'd stop the VM, revert to the previous snapshot and then pull the most recent commit from github. I'd test again, then make changes and push any changes.
- This script will setup docker, k3d, create a new k3s cluster (inside docker), install kubectl on the host, and install argocd.
- This script does not set up the project at all. That can be done within the ArgoCD WebGUI. This script just sets up all the tools needed to get started with the WebGUI.
- The WebGUI for ArgoCD is available at localhost:8080

### Create Manifest files

- The Manifest files are a part of the project that tells ArgoCD how to build your app in kubernetes.
- In these manifest files, you'll need to define the Docker Image you want to use and the tag to use. You'll also indicate the topology of your application.
- In ArgoCD later on when you create the application, you'll indicate which repo to use for configuration. That's the repo we're going to create right now.

- I ran git init inside my p3/confs/dpentlan_IoT_part_3 folder, so I'll have a git repo inside of my project repo. 
- Inside here, I created another folder called plain_yaml which will hold our manifest files. It cannot be in the root directory of our repo because ArgoCD won't allow that for some reason.

- I created 2 files `deployment.yaml` and `service.yaml`. Similar to in Part 2 when we needed to define the organization of our application, we will do the same here with these files. `deployment.yaml` will describe our deployment and `service.yaml` will describe a service. These will be fairly simple.

`deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wil42-app
  namespace: dev
spec:
  replicas: 1
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: wil42-app
  template:
    metadata:
      labels:
        app: wil42-app
    spec:
      containers:
        - image: wil42/playground:v1
          name: wil42-app
          ports:
            - containerPort: 8888
```

`service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: wil42-app
spec:
  ports:
  - port: 8888 # Port outside
    targetPort: 8888 # Port inside
  selector:
    app: wil42-app
```

### Create Application Deployment

- Start by logging into the ArgoCD WebGUI. Username is admin, Password should be printed to your terminal.
- Click on "+ New APP" to create a new app.

- NOTE: I followed this tutorial for my first setup: https://www.youtube.com/watch?v=JLrR9RV9AFA

- Application name = dpentlan-webapp
- Project name = default
- Sync Policy = Manual
- Leave all boxes unchecked except Auto-create namespace. Check that one.
- Repository Url = https://github.com/Drewski6/dpentlan_IoT_part_3
  - For this, I had to create a repo on github. The subject stipulated that it needed my school id in the repo name.
- Revision = HEAD
- Path = plain_yaml
- Destination = https://kubernetes.default.svc
  - This was the default option for this field. Honestly, I don't know what else it would even put here.
- Namespace = dev
  - Must be 'dev' as stipulated by the subject.
- All other fields left at their default values

- On the top click "Create" and ArgoCD will use the git repo to create your application using the manifest files.





















# List of Commands used during vagrant tutorial when I was doing that

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