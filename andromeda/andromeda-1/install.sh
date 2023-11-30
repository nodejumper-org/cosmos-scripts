#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="andromeda-1"
CHAIN_DENOM="uandr"
BINARY_NAME="andromedad"
BINARY_VERSION_TAG="andromeda-1-v0.1.0"
CHEAT_SHEET="https://nodejumper.io/andromeda/cheat-sheet"

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
rm -rf andromedad
git clone https://github.com/andromedaprotocol/andromedad.git
cd andromedad || return
git checkout andromeda-1-v0.1.0
make install

andromedad config keyring-backend file
andromedad config chain-id $CHAIN_ID
andromedad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/andromedaprotocol/mainnet/release/genesis.json > $HOME/.andromeda/config/genesis.json
curl -s https://snapshots.nodejumper.io/andromeda-testnet/addrbook.json > $HOME/.andromeda/config/addrbook.json

SEEDS=""
PEERS="e4c2267b90c7cfbb45090ab7647dc01df97f58f9@andromeda-m.peer.stavr.tech:4376,26cdc42778d24c8b0b0b68ed07c97685bfd8682f@178.162.165.65:26656,17dda7b03ce866dbe36c048282fb742dd895a489@95.56.244.244:56659,0f310196e29d1f289966141e22caa72afaea8060@seeds.cros-nest.com:46656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.andromeda/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.andromeda/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.andromeda/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "17"|g' $HOME/.andromeda/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.andromeda/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uandr"|g' $HOME/.andromeda/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.andromeda/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/andromedad.service > /dev/null << EOF
[Unit]
Description=Andromeda testnet Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which andromedad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

andromedad tendermint unsafe-reset-all --home $HOME/.andromeda --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots.nodejumper.io/andromeda/info.json | jq -r .fileName)
curl "https://snapshots.nodejumper.io/andromeda/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.andromeda"

sudo systemctl daemon-reload
sudo systemctl enable andromedad
sudo systemctl start andromedad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
