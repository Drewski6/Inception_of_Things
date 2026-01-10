# Inception_of_Things

- This is my Inception of Things project. Here, I'm documenting the steps I took to install all the necessary software on my host and inside the VM.
- Specifically, these are the commands I used in the terminal or in Virtual Box to set things up.

## Create VM in Virtual Box

- You know how to do this. I made a small ubuntu desktop VM.

## Possible Host Machine Issue

- If you get the error where the OS doesnt want to run any VMs because another hypervisor is using VT-x (this most commonly happens when I restart Ubuntu), use this command:

```bash
sudo rmmod kvm_intel && sudo rmmod kvm
```

## Starting VM

- Enable portforwarding in Virtual Box on the host with settings:

Name   | Protocol | Host IP   | Host Port | Guest IP | Guest Port
-------|----------|-----------|-----------|----------|-----------
Rule 1 | TCP      | 127.0.0.1 | 2233      | [Blank]  | 22        

- SSH into VM using VS Code (if you want).

## Setup Commands inside VM

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install openssh-server git
ssh-keygen -t ed25519 -C "myemailaddress@example.com"
nano ~/.ssh/authorized_keys # Add public ssh key of client.
git clone <IoT git repo link>
```

- Take a snapshot of initial setup

## Install Vagrant

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

