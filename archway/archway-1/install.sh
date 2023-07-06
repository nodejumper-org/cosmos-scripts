#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="archway-1"
CHAIN_DENOM="aarch"
BINARY_NAME="archwayd"
BINARY_VERSION_TAG="v1.0.1"
CHEAT_SHEET="https://nodejumper.io/archway/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

mkdir -p $HOME/go/bin
curl -L https://github.com/archway-network/archway/releases/download/v1.0.1/archwayd_linux_amd64 > $HOME/go/bin/archwayd
chmod +x $HOME/go/bin/archwayd

archwayd init "$NODE_MONIKER" --chain-id $CHAIN_ID
archwayd config chain-id $CHAIN_ID
archwayd config keyring-backend file

rm $HOME/.archway/config/genesis.json
curl -Ls https://github.com/archway-network/networks/raw/main/archway-1/genesis/genesis.json.gz > $HOME/.archway/config/genesis.json.gz
gzip -d $HOME/.archway/config/genesis.json.gz
# todo: curl -s https://snapshots2.nodejumper.io/archway/addrbook.json > $HOME/.archway/config/addrbook.json

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.archway/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.archway/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.archway/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.archway/config/app.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001aarch"|g' $HOME/.archway/config/app.toml

SEEDS="3ba7bf08f00e228026177e9cdc027f6ef6eb2b39@35.232.234.58:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.archway/config/config.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.archway/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/archwayd.service > /dev/null << EOF
[Unit]
Description=Archway Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which archwayd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

archwayd tendermint unsafe-reset-all --home $HOME/.archway --keep-addr-book

# todo:
#SNAP_NAME=$(curl -s https://snapshots2.nodejumper.io/archway/info.json | jq -r .fileName)
#curl "https://snapshots2.nodejumper.io/archway-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.archway"

sudo systemctl daemon-reload
sudo systemctl enable archwayd
sudo systemctl start archwayd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
