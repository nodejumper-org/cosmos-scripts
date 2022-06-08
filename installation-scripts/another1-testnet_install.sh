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
rm -rf anone
git clone https://github.com/notional-labs/anone
cd anone || return
git checkout testnet-1.0.3
make install
anoned version - testnet-1.0.3

# replace nodejumper with your own moniker, if you'd like
anoned config chain-id anone-testnet-1
anoned init "${1:-nodejumper}" --chain-id anone-testnet-1

curl https://raw.githubusercontent.com/notional-labs/anone/master/networks/testnet-1/genesis.json > $HOME/.anone/config/genesis.json
sha256sum $HOME/.anone/config/genesis.json # ba7bea692350ca8918542a26cabd5616dbebe1ff109092cb1e98c864da58dabf

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uan1"|g' $HOME/.anone/config/app.toml
seeds=""
peers="3137535a0d6cc552bd44512ac6a11f4a41c3b3e4@rpc1-testnet.nodejumper.io:26656,49a49db05e945fc38b7a1bc00352cafdaef2176c@95.217.121.243:2280,80f0ef5d7c432d2bae99dc8437a9c3db464890cd@65.108.128.139:2280"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.anone/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.anone/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.anone/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.anone/config/app.toml

sudo tee /etc/systemd/system/anoned.service > /dev/null << EOF
[Unit]
Description=Another-1 Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which anoned) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

anoned unsafe-reset-all
rm -rf $HOME/.anone/data
cd $HOME/.anone || return

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/another1-testnet/ | egrep -o ">anone-testnet-1.*\.tar.lz4" | tr -d ">")
curl https://snapshots1-testnet.nodejumper.io/another1-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf -

sudo systemctl daemon-reload
sudo systemctl enable anoned
sudo systemctl restart anoned
