#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="centauri-1"
CHAIN_DENOM="ppica"
BINARY_NAME="centaurid"
BINARY_VERSION_TAG="v4.0.1"
CHEAT_SHEET="https://nodejumper.io/сomposable/cheat-sheet"

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
rm -rf composable-centauri
git clone https://github.com/notional-labs/composable-centauri
cd composable-centauri || return
git checkout v4.0.1
make install
centaurid version # v4.0.1

centaurid config chain-id $CHAIN_ID
centaurid config keyring-backend file
centaurid init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -L https://raw.githubusercontent.com/notional-labs/composable-networks/main/mainnet/genesis.json > $HOME/.banksy/config/genesis.json
curl -s https://snapshots1.nodejumper.io/composable/addrbook.json > $HOME/.banksy/config/addrbook.json

SEEDS="c7f52f81ee1b1f7107fc78ca2de476c730e00be9@65.109.80.150:2635"
PEERS="4cb008db9c8ae2eb5c751006b977d6910e990c5d@65.108.71.163:2630,63559b939442512ed82d2ded46d02ab1021ea29a@95.214.55.138:53656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.banksy/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.banksy/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.banksy/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.banksy/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.banksy/config/app.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ppica"|g' $HOME/.banksy/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.banksy/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/centaurid.service > /dev/null << EOF
[Unit]
Description=Composable Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which centaurid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
WorkingDirectory=$HOME/.banksy
[Install]
WantedBy=multi-user.target
EOF

centaurid tendermint unsafe-reset-all --home $HOME/.banksy --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1.nodejumper.io/composable/info.json | jq -r .fileName)
curl "https://snapshots1.nodejumper.io/composable/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.banksy"

sudo systemctl daemon-reload
sudo systemctl enable centaurid
sudo systemctl start centaurid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
