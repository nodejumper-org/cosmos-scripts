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
rm -rf rizon
git clone https://github.com/rizon-world/rizon.git
cd rizon || return
git checkout v0.3.0
make install
rizond version # v0.3.0

# replace nodejumper with your own moniker, if you'd like
rizond config chain-id titan-1
rizond init "${1:-nodejumper}" --chain-id titan-1

curl https://raw.githubusercontent.com/rizon-world/mainnet/master/genesis.json > $HOME/.rizon/config/genesis.json
sha256sum $HOME/.rizon/config/genesis.json # 6d5602e3746affea1096c729768bffd1f60633dfe88ae705f018d70fd3e90302  -

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uatolo"|g' $HOME/.rizon/config/app.toml
seeds="83c9cdc2db2b4eff4acc9cd7d664ad5ae6191080@seed-1.mainnet.rizon.world:26656,ae1476777536e2be26507c4fbcf86b67540adb64@seed-2.mainnet.rizon.world:26656,8abf316257a264dc8744dee6be4981cfbbcaf4e4@seed-3.mainnet.rizon.world:26656"
peers="0d51e8b9eb24f412dffc855c7bd854a8ecb3dff5@rpc1.nodejumper.io:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.rizon/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.rizon/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.rizon/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.rizon/config/app.toml

sudo tee /etc/systemd/system/rizond.service > /dev/null << EOF
[Unit]
Description=Rizon Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which rizond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

rizond unsafe-reset-all

SNAP_RPC="http://rpc1.nodejumper.io:26657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.rizon/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable rizond
sudo systemctl restart rizond
