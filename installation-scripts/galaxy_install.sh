#!/bin/bash

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

read -p "Enter node moniker: " NODEMONIKER

CHAIN_ID="galaxy-1"
BINARY="galaxyd"
CHEAT_SHEET="https://nodejumper.io/galaxy/cheat-sheet"

echo "=================================================================================================="
echo -e "Node moniker: \e[1m\e[1;96m$NODEMONIKER\e[0m"
echo -e "Wallet name:  \e[1m\e[1;96mwallet\e[0m"
echo -e "Chain id:     \e[1m\e[1;96m$CHAIN_ID\e[0m"
echo "=================================================================================================="
sleep 2

. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/install_common_packages.sh)

echo -e "\e[1m\e[1;96m4. Building binaries... \e[0m" && sleep 1

cd || return
rm -rf galaxy
git clone https://github.com/galaxies-labs/galaxy
cd galaxy || return
git checkout v1.0.0
make install
galaxyd version # launch-gentxs

# replace nodejumper with your own moniker, if you'd like
galaxyd config chain-id $CHAIN_ID
galaxyd init $NODEMONIKER --chain-id $CHAIN_ID

curl https://media.githubusercontent.com/media/galaxies-labs/networks/main/galaxy-1/genesis.json > $HOME/.galaxy/config/genesis.json
sha256sum $HOME/.galaxy/config/genesis.json # 2003cfaca53c3f9120a36957103fbbe6562d4f6c6c50a3e9502c49dbb8e2ba5b

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uglx"|g' $HOME/.galaxy/config/app.toml
seeds=""
peers="1e9aa80732182fd7ea005fc138b05e361b9c040d@galaxy.nodejumper.io:30656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.galaxy/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.galaxy/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.galaxy/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.galaxy/config/app.toml

echo -e "\e[1m\e[1;96m5. Starting service and synchronization... \e[0m" && sleep 1

sudo tee /etc/systemd/system/galaxyd.service > /dev/null << EOF
[Unit]
Description=Galaxy Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which galaxyd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

galaxyd unsafe-reset-all

SNAP_RPC="https://galaxy.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.galaxy/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable galaxyd
sudo systemctl restart galaxyd

echo "=================================================================================================="
echo -e "Check logs:            \e[1m\e[1;96msudo journalctl -u $BINARY -f --no-hostname -o cat \e[0m"
echo -e "Check synchronization: \e[1m\e[1;96m$BINARY status 2>&1 | jq .SyncInfo.catching_up\e[0m"
echo -e "More commands:         \e[1m\e[1;96m$CHEAT_SHEET\e[0m"