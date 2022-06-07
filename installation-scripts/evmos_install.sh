#!/bin/bash

sudo apt update
sudo apt install -y make gcc jq curl git

if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/installation-scripts/go_install.sh")
  . .bash_profile
fi
go version - go version goX.XX.X linux/amd64

cd || return
rm -rf evmos
git clone https://github.com/tharsis/evmos
cd evmos || return
git checkout v4.0.1
make install
evmosd version - 4.0.1

# replace nodejumper with your own moniker, if you'd like
evmosd config chain-id evmos_9001-2
evmosd init "${1:-nodejumper}" --chain-id evmos_9001-2

cd || return
curl -# -L -O https://github.com/tharsis/mainnet/raw/main/evmos_9001-2/genesis.json.zip
unzip genesis.json.zip
rm genesis.json.zip
mv -f genesis.json ~/.evmosd/config/genesis.json
sha256sum ~/.evmosd/config/genesis.json # 4aa13da5eb4b9705ae8a7c3e09d1c36b92d08247dad2a6ed1844d031fcfe296c

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001aevmos"|g' ~/.evmosd/config/app.toml
seeds=""
peers="b984dc3cb4c9d13546822942ac1213e133373ee6@135.181.139.171:36656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' ~/.evmosd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' ~/.evmosd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' ~/.evmosd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' ~/.evmosd/config/app.toml

sudo tee /etc/systemd/system/evmosd.service > /dev/null << EOF
[Unit]
Description=Evmos Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which evmosd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

evmosd tendermint unsafe-reset-all --home ~/.evmosd

SNAP_RPC="http://rpc3.nodejumper.io:36657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" ~/.evmosd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable evmosd
sudo systemctl restart evmosd
