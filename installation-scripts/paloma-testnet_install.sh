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
curl -L https://github.com/CosmWasm/wasmvm/raw/main/api/libwasmvm.x86_64.so > libwasmvm.x86_64.so
sudo mv -f libwasmvm.x86_64.so /usr/lib/libwasmvm.x86_64.so
curl -L paloma.tar.gz https://github.com/palomachain/paloma/releases/download/v0.2.5-prealpha/paloma_0.2.5-prealpha_Linux_x86_64.tar.gz > paloma.tar.gz
tar -xvzf paloma.tar.gz
rm -rf paloma.tar.gz
sudo mv -f palomad /usr/local/bin/palomad
palomad version # v0.2.5-prealpha

# replace nodejumper with your own moniker, if you'd like
palomad config chain-id paloma-testnet-6
palomad init "${1:-nodejumper}" --chain-id paloma-testnet-6

curl https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-6/genesis.json > $HOME/.paloma/config/genesis.json
sha256sum $HOME/.paloma/config/genesis.json # bad4a385822e25d8357c6b0b6ba4f4ab7c47355b105d02397994f718fb9a407a

curl https://raw.githubusercontent.com/palomachain/testnet/master/paloma-testnet-5/addrbook.json > $HOME/.paloma/config/addrbook.json

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ugrain"|g' $HOME/.paloma/config/app.toml
seeds=""
peers="dfaf45e5de50626edd48a866f0ceddf6a1aadab8@rpc1-testnet.nodejumper.io:33656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.paloma/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.paloma/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.paloma/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.paloma/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.paloma/config/app.toml

sudo tee /etc/systemd/system/palomad.service > /dev/null << EOF
[Unit]
Description=Paloma Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which palomad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

palomad tendermint unsafe-reset-all --home $HOME/.paloma --keep-addr-book

SNAP_RPC="http://rpc1-testnet.nodejumper.io:33657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.paloma/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable palomad
sudo systemctl restart palomad
