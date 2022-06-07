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
rm -rf deweb
git clone https://github.com/deweb-services/deweb.git
cd deweb || return
git checkout v0.2
make install
dewebd version - 0.2

# replace nodejumper with your own moniker, if you'd like
dewebd config chain-id deweb-testnet-1
dewebd init "${1:-nodejumper}" --chain-id deweb-testnet-1

curl https://raw.githubusercontent.com/deweb-services/deweb/main/genesis.json > ~/.deweb/config/genesis.json
sha256sum ~/.deweb/config/genesis.json # 13bf101d673990cb39e6af96e3c7e183da79bd89f6d249e9dc797ae81b3573c2

curl https://raw.githubusercontent.com/encipher88/deweb/main/addrbook.json > ~/.deweb/config/addrbook.json
sha256sum ~/.deweb/config/addrbook.json # ba7bea692350ca8918542a26cabd5616dbebe1ff109092cb1e98c864da58dabf

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001udws"|g' ~/.deweb/config/app.toml
seeds=""
peers="9440fa39f85bea005514f0191d4550a1c9d310bb@rpc1-testnet.nodejumper.io:27656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' ~/.deweb/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' ~/.deweb/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' ~/.deweb/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' ~/.deweb/config/app.toml

sudo tee /etc/systemd/system/dewebd.service > /dev/null << EOF
[Unit]
Description=DWS Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which dewebd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

dewebd unsafe-reset-all
rm -rf ~/.deweb/data
cd ~/.deweb || return

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/dws-testnet/ | egrep -o ">deweb-testnet-1.*\.tar.lz4" | tr -d ">")
curl https://snapshots1-testnet.nodejumper.io/dws-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable dewebd
sudo systemctl restart dewebd
