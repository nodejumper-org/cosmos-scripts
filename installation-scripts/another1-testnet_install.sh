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
rm -rf anone
git clone https://github.com/notional-labs/anone
cd anone || return
git checkout testnet-1.0.3
make install
anoned version # testnet-1.0.3

# replace nodejumper with your own moniker, if you'd like
anoned config chain-id anone-testnet-1
anoned init "${1:-nodejumper}" --chain-id anone-testnet-1

curl https://raw.githubusercontent.com/notional-labs/anone/master/networks/testnet-1/genesis.json > $HOME/.anone/config/genesis.json
sha256sum $HOME/.anone/config/genesis.json # ba7bea692350ca8918542a26cabd5616dbebe1ff109092cb1e98c864da58dabf

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uan1"|g' $HOME/.anone/config/app.toml
seeds=""
peers="2b540c43d640befc35959eb062c8505612b7d67f@rpc1-testnet.nodejumper.io:26656"
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

SNAP_RPC="http://rpc1-testnet.nodejumper.io:26657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.anone/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable anoned
sudo systemctl restart anoned
