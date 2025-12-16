# Inception_of_Things

## Starting VM

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install openssh-server
ssh-keygen -t ed25519 -C "myemailaddress@example.com"
nano ~/.ssh/authorized_keys # Add public ssh key of client.
```
