#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="althea_7357-1"
CHAIN_DENOM="ualthea"
BINARY_NAME="althea"
BINARY_VERSION_TAG="v0.3.2"
CHEAT_SHEET="https://nodejumper.io/nibiru-testnet/cheat-sheet"

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
rm -rf althea-chain
git clone https://github.com/althea-net/althea-chain
cd althea-chain || return
git checkout v0.3.2
make install
althea version # v0.3.2

althea config keyring-backend test
althea config chain-id $CHAIN_ID
althea init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/althea-net/althea-chain-docs/main/testnet-3-genesis.json > $HOME/.althea/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/althea-testnet/addrbook.json > $HOME/.althea/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.althea/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.althea/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.althea/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.althea/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.althea/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ualthea"|g' $HOME/.althea/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.althea/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/althead.service > /dev/null << EOF
[Unit]
Description=Althea Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which althea) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

althea tendermint unsafe-reset-all --home $HOME/.althea --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/althea-testnet/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/althea-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C $HOME/.althea

sudo systemctl daemon-reload
sudo systemctl enable althead
sudo systemctl start althead

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
