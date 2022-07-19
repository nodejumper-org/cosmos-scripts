#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

# check dependencies and install if needed
pkgs=("curl" "jq" "git" "build-essential" "lz4")
for pkg in "${pkgs[@]}"; do
  pkg_installed=$(dpkg-query -W --showformat='${Status}\n' $pkg 2>/dev/null|grep "install ok installed")
  if [ "" = "$pkg_installed" ]; then
    printCyan "Updating packages..." && sleep 1
    sudo apt update
    printCyan "Installing dependencies..." && sleep 1
    sudo apt install -y jq curl git build-essential lz4
    break
  fi
done

# check go and install if needed
if [ ! -f "/usr/local/go/bin/go" ]; then
  printCyan "Installing go..." && sleep 1
  bash <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/go_install.sh")
  source .bash_profile
fi

printCyan "Installed: $(go version)"
