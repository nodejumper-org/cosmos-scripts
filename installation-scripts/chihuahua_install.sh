#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/logo/logo.sh)

sudo apt update
sudo apt install -y make gcc jq curl git

if [ ! -f "/usr/local/go/bin/go" ]; then
  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/installation-scripts/go_install.sh")
  . .bash_profile
fi
go version # go version goX.XX.X linux/amd64

cd || return
rm -rf chihuahua
git clone https://github.com/ChihuahuaChain/chihuahua.git
cd chihuahua || return
git checkout v1.1.1
make install
chihuahuad version # v1.1.1

# replace nodejumper with your own moniker, if you'd like
chihuahuad config chain-id chihuahua-1
chihuahuad init "${1:-nodejumper}" --chain-id chihuahua-1

curl https://raw.githubusercontent.com/ChihuahuaChain/mainnet/main/genesis.json > $HOME/.chihuahua/config/genesis.json
sha256sum $HOME/.chihuahua/config/genesis.json # 200a64f201c6b5799d81bcf52a25ce4eb1c0eac3f7c8c5eaa8335e75c5763f91

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uhuahua"|g' $HOME/.chihuahua/config/app.toml
seeds="4936e377b4d4f17048f8961838a5035a4d21240c@chihuahua-seed-01.mercury-nodes.net:29540"
peers="c9b1385f81bec76dd6a84311de997d1e783dba53@rpc1.nodejumper.io:29656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.chihuahua/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.chihuahua/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.chihuahua/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.chihuahua/config/app.toml

sudo tee /etc/systemd/system/chihuahuad.service > /dev/null << EOF
[Unit]
Description=Chihuahua Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which chihuahuad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

chihuahuad unsafe-reset-all

SNAP_RPC="http://rpc1.nodejumper.io:29657"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.chihuahua/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable chihuahuad
sudo systemctl restart chihuahuad
