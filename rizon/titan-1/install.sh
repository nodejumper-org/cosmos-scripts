#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="titan-1"
CHAIN_DENOM="uatolo"
BINARY_NAME="rizond"
BINARY_VERSION_TAG="v0.4.1"
CHEAT_SHEET="https://nodejumper.io/rizon/cheat-sheet"

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
rm -rf rizon
git clone https://github.com/rizon-world/rizon.git
cd rizon || return
git checkout v0.4.1
make install
rizond version # v0.4.1

rizond config chain-id $CHAIN_ID
rizond init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/rizon-world/mainnet/master/genesis.json > $HOME/.rizon/config/genesis.json
curl -s https://snapshots1.nodejumper.io/rizon/addrbook.json > $HOME/.rizon/config/addrbook.json

SEEDS="83c9cdc2db2b4eff4acc9cd7d664ad5ae6191080@seed-1.mainnet.rizon.world:26656,ae1476777536e2be26507c4fbcf86b67540adb64@seed-2.mainnet.rizon.world:26656,8abf316257a264dc8744dee6be4981cfbbcaf4e4@seed-3.mainnet.rizon.world:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.rizon/config/config.toml

PRUNING_INTERVAL=$(shuf -n1 -e 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.rizon/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.rizon/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "'$PRUNING_INTERVAL'"|g' $HOME/.rizon/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.rizon/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uatolo"|g' $HOME/.rizon/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.rizon/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

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

rizond tendermint unsafe-reset-all --home $HOME/.rizon --keep-addr-book

SNAP_RPC="https://rizon.nodejumper.io:443"

LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i 's|^enable *=.*|enable = true|' $HOME/.rizon/config/config.toml
sed -i 's|^rpc_servers *=.*|rpc_servers = "'$SNAP_RPC,$SNAP_RPC'"|' $HOME/.rizon/config/config.toml
sed -i 's|^trust_height *=.*|trust_height = '$BLOCK_HEIGHT'|' $HOME/.rizon/config/config.toml
sed -i 's|^trust_hash *=.*|trust_hash = "'$TRUST_HASH'"|' $HOME/.rizon/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable rizond
sudo systemctl start rizond

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
