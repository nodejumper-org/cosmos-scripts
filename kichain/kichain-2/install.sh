#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="kichain-2"
CHAIN_DENOM="uxki"
BINARY_NAME="kid"
BINARY_VERSION_TAG="v4.1.0"
CHEAT_SHEET="https://nodejumper.io/kichain/cheat-sheet"

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
rm -rf ki-tools
git clone https://github.com/KiFoundation/ki-tools.git
cd ki-tools || return
git checkout 4.2.0
make install
kid version # Mainnet-4.2.0

kid config chain-id $CHAIN_ID
kid init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/KiFoundation/ki-networks/v0.1/Mainnet/kichain-2/genesis.json > $HOME/.kid/config/genesis.json
curl -s https://snapshots1.nodejumper.io/kichain/addrbook.json > $HOME/.kid/config/addrbook.json

SEEDS="24cbccfa8813accd0ebdb09e7cdb54cff2e8fcd9@51.89.166.197:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.kid/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.kid/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.kid/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.kid/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.kid/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uxki"|g' $HOME/.kid/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.kid/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/kid.service > /dev/null << EOF
[Unit]
Description=Kichain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which kid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

kid tendermint unsafe-reset-all --home $HOME/.kid --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1.nodejumper.io/kichain/info.json | jq -r .fileName)
curl "https://snapshots1.nodejumper.io/kichain/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.kid"

sudo systemctl daemon-reload
sudo systemctl enable kid
sudo systemctl start kid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
