#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printCyan "1. Updating packages..." && sleep 1
sudo apt update

printCyan "2. Installing dependencies..." && sleep 1
sudo apt install -y make gcc jq curl git lz4 build-essential chrony unzip gzip

printCyan "3. Installing go..." && sleep 1
if ! [ -x "$(command -v go)" ]; then
  source <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/go_install.sh")
  source .bash_profile
fi

echo "$(go version)"
