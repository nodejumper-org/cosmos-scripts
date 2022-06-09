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
rm -rf kid
git clone https://github.com/KiFoundation/ki-tools.git
cd ki-tools || return
git checkout -b v2.0.1 tags/2.0.1
make install
kid version # Mainnet-IBC-v2.0.1-889c4a2ca6b228247f5cb9366c3c0c894592da27

# replace nodejumper with your own moniker, if you'd like
kid config chain-id kichain-2
kid init "${1:-nodejumper}" --chain-id kichain-2

curl https://raw.githubusercontent.com/KiFoundation/ki-networks/v0.1/Mainnet/kichain-2/genesis.json > $HOME/.kid/config/genesis.json
sha256sum $HOME/.kid/config/genesis.json # 0059e1cd40da1ece7f14133509c44980cf6b5c5407a877ce17edd3bc6266708c

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uxki"|g' $HOME/.kid/config/app.toml
seeds="24cbccfa8813accd0ebdb09e7cdb54cff2e8fcd9@51.89.166.197:26656"
peers="766ed622c79fa9cfd668db9741a1f72a5751e0cd@rpc1.nodejumper.io:28656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.kid/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.kid/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.kid/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.kid/config/app.toml

sudo tee /etc/systemd/system/kid.service > /dev/null << EOF
[Unit]
Description=Kichain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which kid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

kid unsafe-reset-all

SNAP_RPC="http://rpc1.nodejumper.io:28657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.kid/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable kid
sudo systemctl restart kid
