#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="banksy-testnet-3"
CHAIN_DENOM="ppica"
BINARY_NAME="banksyd"
BINARY_VERSION_TAG="v2.3.5"
CHEAT_SHEET="https://nodejumper.io/сomposable-testnet-3/cheat-sheet"

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
rm -rf composable-testnet
git clone https://github.com/notional-labs/composable-testnet.git
cd composable-testnet || return
git checkout v2.3.5
make install

banksyd config chain-id $CHAIN_ID
banksyd config keyring-backend test
banksyd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -L https://raw.githubusercontent.com/notional-labs/composable-networks/main/banksy-testnet-3/genesis.json > $HOME/.banksy/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/composable-testnet-3/addrbook.json > $HOME/.banksy/config/addrbook.json

SEEDS="364b8245e72f083b0aa3e0d59b832020b66e9e9d@65.109.80.150:21500"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.banksy/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.banksy/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.banksy/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.banksy/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.banksy/config/app.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ppica"|g' $HOME/.banksy/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.banksy/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/banksyd.service > /dev/null << EOF
[Unit]
Description=Composable Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which banksyd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
WorkingDirectory=$HOME
[Install]
WantedBy=multi-user.target
EOF

banksyd tendermint unsafe-reset-all --home $HOME/.banksy --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/composable-testnet-3/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/composable-testnet-3/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.banksy"

sudo systemctl daemon-reload
sudo systemctl enable banksyd
sudo systemctl start banksyd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
