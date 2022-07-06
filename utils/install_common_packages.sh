#!/bin/bash

echo -e "\e[1m\e[1;96m1. Updating packages... \e[0m" && sleep 1
sudo apt update

echo -e "\e[1m\e[1;96m2. Installing dependencies... \e[0m" && sleep 1
sudo apt install -y make gcc jq curl git snapd build-essential
sudo snap install lz4

echo -e "\e[1m\e[1;96m3. Installing go... \e[0m" && sleep 1
if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/go_install.sh")
  . .bash_profile
fi
go version