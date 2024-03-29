#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="ollo-testnet-1"
CHAIN_DENOM="utollo"
BINARY_NAME="ollod"
BINARY_VERSION_TAG="v0.0.1"
CHEAT_SHEET="https://nodejumper.io/ollo-testnet/cheat-sheet"

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
rm -rf ollo
git clone https://github.com/OllO-Station/ollo.git
cd ollo || return
git checkout v0.0.1
make install
ollod version # latest

ollod config keyring-backend test
ollod config chain-id $CHAIN_ID
ollod init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/OllO-Station/networks/master/ollo-testnet-1/genesis.json > $HOME/.ollo/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/ollo-testnet/addrbook.json > $HOME/.ollo/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.ollo/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.ollo/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.ollo/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.ollo/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.ollo/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utollo"|g' $HOME/.ollo/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.ollo/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/ollod.service > /dev/null << EOF
[Unit]
Description=Ollo Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ollod) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

ollod tendermint unsafe-reset-all --home $HOME/.ollo --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/ollo-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/ollo-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.ollo"

sudo systemctl daemon-reload
sudo systemctl enable ollod
sudo systemctl start ollod

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
