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
rm -rf uptick
git clone https://github.com/UptickNetwork/uptick.git
cd uptick || return
make install
uptickd version # v0.1.0

# replace nodejumper with your own moniker, if you'd like
uptickd config chain-id uptick_7776-1
uptickd init "${1:-nodejumper}" --chain-id uptick_7776-1

curl https://raw.githubusercontent.com/UptickNetwork/uptick-testnet/main/uptick_7776-1/genesis.json > $HOME/.uptickd/config/genesis.json
sha256sum $HOME/.uptickd/config/genesis.json # 1ca389503310668cad2a38662c7f84045699839cba48d13ce2af31956442c8b5

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001auptick"|g' $HOME/.uptickd/config/app.toml
seeds="7aad751eb956d65388f0cc37ab2ea179e2143e41@seed0.testnet.uptick.network:26656,7e6c759bcf03641c65659f1b9b2f05ec9de7391b@seed1.testnet.uptick.network:26656"
peers=""
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.uptickd/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.uptickd/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.uptickd/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.uptickd/config/app.toml

sudo tee /etc/systemd/system/uptickd.service > /dev/null << EOF
[Unit]
Description=Uptick Network Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which uptickd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

uptickd tendermint unsafe-reset-all --keep-addr-book

SNAP_RPC="http://rpc1-testnet.nodejumper.io:30657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.uptickd/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable uptickd
sudo systemctl restart uptickd
