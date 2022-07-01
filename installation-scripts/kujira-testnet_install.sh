#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

sudo apt update
sudo apt install -y make gcc jq curl git

if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/go_install.sh")
  . .bash_profile
fi
go version # go version goX.XX.X linux/amd64

cd || return
rm -rf kujira-core
git clone https://github.com/Team-Kujira/core kujira-core
cd kujira-core || return
git checkout v0.4.0
make install
kujirad version # 0.4.0

# replace nodejumper with your own moniker, if you'd like
kujirad config chain-id harpoon-4
kujirad init "${1:-nodejumper}" --chain-id harpoon-4 -o

curl https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/harpoon-4.json > $HOME/.kujira/config/genesis.json
sha256sum $HOME/.kujira/config/genesis.json # c5e258a28511b7f3f4e58993edd3b98ec7c716fe20b5c5813eec9babb696bd02

curl https://raw.githubusercontent.com/Team-Kujira/networks/master/testnet/addrbook.json > $HOME/.kujira/config/addrbook.json
sha256sum $HOME/.kujira/config/addrbook.json # 620fe1d5caf6544d61ea887c0c84664a1d3a0ea150a34dee21800c704262ba03

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ukuji"|g' $HOME/.kujira/config/app.toml
seeds=""
peers="eaa7e55efc03f23c5f461f71c06d444693d5352b@rpc1-testnet.nodejumper.io:29656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.kujira/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.kujira/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.kujira/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.kujira/config/app.toml

sudo tee /etc/systemd/system/kujirad.service > /dev/null << EOF
[Unit]
Description=Kujira Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which kujirad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

kujirad tendermint unsafe-reset-all --home $HOME/.kujira --keep-addr-book

SNAP_RPC="http://rpc1-testnet.nodejumper.io:29657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.kujira/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable kujirad
sudo systemctl restart kujirad
