#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="jackal-1"
CHAIN_DENOM="ujkl"
BINARY_NAME="canined"
BINARY_VERSION_TAG="v2.1.0"
CHEAT_SHEET="https://nodejumper.io/jackal-testnet/cheat-sheet"

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
rm -rf canine-chain
git clone https://github.com/JackalLabs/canine-chain.git
cd canine-chain || return
git checkout v2.1.0
make install
canined version # 2.1.0

canined config chain-id $CHAIN_ID
canined init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/JackalLabs/canine-mainnet-genesis/main/genesis/genesis.json > $HOME/.canine/config/genesis.json
curl -s https://snapshots1.nodejumper.io/jackal/addrbook.json > $HOME/.canine/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.canine/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.canine/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.canine/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.canine/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.canine/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025ujkl"|g' $HOME/.canine/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.canine/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/canined.service > /dev/null << EOF
[Unit]
Description=Jackal Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which canined) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

canined tendermint unsafe-reset-all --home $HOME/.canine --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1.nodejumper.io/jackal/info.json | jq -r .fileName)
curl "https://snapshots1.nodejumper.io/jackal/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.canine"

sudo systemctl daemon-reload
sudo systemctl enable canined
sudo systemctl start canined

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
