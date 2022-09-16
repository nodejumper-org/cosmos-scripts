#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/common.sh)

printLogo

read -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="galaxy-1"
CHAIN_DENOM="uglx"
BINARY="galaxyd"
CHEAT_SHEET="https://nodejumper.io/galaxy/cheat-sheet"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf galaxy
git clone https://github.com/galaxies-labs/galaxy
cd galaxy || return
git checkout v1.0.0
make install
galaxyd version # launch-gentxs

galaxyd config chain-id $CHAIN_ID
galaxyd init $NODE_MONIKER --chain-id $CHAIN_ID

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

printCyan "5. Starting service and synchronization..." && sleep 1

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

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
