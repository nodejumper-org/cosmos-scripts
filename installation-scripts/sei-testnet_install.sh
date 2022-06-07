#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/logo/logo.sh)

sudo apt update
sudo apt install -y make gcc jq curl git snapd
sudo snap install lz4

if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/installation-scripts/go_install.sh")
  . .bash_profile
fi
go version - go version goX.XX.X linux/amd64

cd || return
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain || return
git checkout 1.0.0beta
go build -o build/seid ./cmd/sei-chaind
mkdir -p ~/go/bin
mv build/seid ~/go/bin
seid version

# replace nodejumper with your own moniker, if you'd like
seid config chain-id sei-testnet-1
seid init "${1:-nodejumper}" --chain-id sei-testnet-1

curl https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-testnet-1/genesis.json > ~/.sei-chain/config/genesis.json
sha256sum ~/.sei-chain/config/genesis.json # d212a915dcde84f1dc2208ca5ee890adfd6ffc5d4ff9a32332f50659b3b5ab1a

curl https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-testnet-1/addrbook.json > ~/.sei-chain/config/addrbook.json
sha256sum ~/.sei-chain/config/addrbook.json # 2ff327d2ab89c9ec56f86c14fdc67cbfc12e4716ae8cecc3bb497d92c4d8411e

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001usei"|g' ~/.sei-chain/config/app.toml
seeds=""
peers="f36276cafd833d805f48ee0c3214b1d1b2f2193e@rpc1-testnet.nodejumper.io:28656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' ~/.sei-chain/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' ~/.sei-chain/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' ~/.sei-chain/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' ~/.sei-chain/config/app.toml

sudo tee /etc/systemd/system/seid.service > /dev/null << EOF
[Unit]
Description=Sei Protocol Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which seid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

seid unsafe-reset-all
rm -rf ~/.sei-chain/data
cd ~/.sei-chain || return

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/sei-testnet/ | egrep -o ">sei-testnet-1.*\.tar.lz4" | tr -d ">")
curl https://snapshots1-testnet.nodejumper.io/sei-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable seid
sudo systemctl restart seid
