#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="Cardchain"
CHAIN_DENOM="ubpf"
BINARY_NAME="Cardchain"
CHEAT_SHEET="https://nodejumper.io/cardchain-testnet/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
curl https://get.ignite.com/DecentralCardGame/Cardchain@latest! | sudo bash
Cardchain version # latest-8103a490

Cardchain config keyring-backend test
Cardchain config chain-id $CHAIN_ID
Cardchain init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl https://raw.githubusercontent.com/DecentralCardGame/Testnet/main/genesis.json > $HOME/.Cardchain/config/genesis.json
sha256sum $HOME/.Cardchain/config/genesis.json # e13a5310f2632e80da02f5c9337d48c151d95c3b8e26bf32bfa97a1c98fe52c0

SEEDS=""
PEERS="c33a6ea0c7f82b4cc99f6f62a0e7ffdb3046a345@cardchain-testnet.nodejumper.io:30656,752cfbb39a24007f7316725e7bbc34c845e7c5f1@45.136.28.158:26658"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.Cardchain/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.Cardchain/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.Cardchain/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "17"|g' $HOME/.Cardchain/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/Cardchaind.service > /dev/null << EOF
[Unit]
Description=Cardchain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which Cardchain) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

Cardchain unsafe-reset-all

SNAP_RPC="https://cardchain-testnet.nodejumper.io:443"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.Cardchain/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable Cardchaind
sudo systemctl start Cardchaind

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u ${BINARY}d -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
