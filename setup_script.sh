# Initial setup of host
sudo apt update && sudo apt upgrade -y
sudo apt install -y git vim openssh-server virtualbox

# Install Vagrant on host machine
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
# NOTE: I had to run this a couple times. I'm not sure why

# init vagrant in the current directory
# vagrant init hashicorp-education/ubuntu-24-04 --box-version 0.1.0
