# Inception_of_Things

## Starting VM

- Enable portforwarding with settings:

Name   | Protocol | Host IP   | Host Port | Guest IP | Guest Port
-------|----------|-----------|-----------|----------|-----------
Rule 1 | TCP      | 127.0.0.1 | 2233      | [Blank]  | 22        

- Setup Commands

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

