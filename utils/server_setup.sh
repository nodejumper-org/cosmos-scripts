#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -p "Enter public SSH key in double quotes(\"): " PUBLIC_SSH_KEY
read -p "Enter new system username: " USERNAME

printCyan "1. Upgrading system packages..." && sleep 1

sudo apt update
sudo apt upgrade -y

printCyan "2. Creating new user: \"$USERNAME\" and configuring SSH ..." && sleep 1

sudo adduser $USERNAME --disabled-password -q
mkdir /home/$USERNAME/.ssh
echo "$PUBLIC_SSH_KEY" > /home/$USERNAME/.ssh/authorized_keys
sudo chown $USERNAME: /home/$USERNAME/.ssh
sudo chown $USERNAME: /home/$USERNAME/.ssh/authorized_keys

echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

sudo sed -i 's/^PermitRootLogin\s.*$/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^ChallengeResponseAuthentication\s.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication\s.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitEmptyPasswords\s.*$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication\s.*$/PubkeyAuthentication yes/' /etc/ssh/sshd_config

sudo systemctl restart sshd

printCyan "3. Installing fail2ban ..." && sleep 1

sudo apt install -y fail2ban

printCyan "4. Installing and configuring firewall ..." && sleep 1

sudo apt install -y ufw
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow 9100
sudo ufw allow 26656
sudo ufw enable

printCyan "5. Making terminal colorful ..." && sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/server-setup/utils/enable_colorful_bash.sh)

printLine

printCyan "Server setup is done." && sleep 1
printCyan "Now you can logout (exit) and login again using ssh $USERNAME@$(wget -qO- eth0.me)" && sleep 1