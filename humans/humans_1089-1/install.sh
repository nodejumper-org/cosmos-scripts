#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="humans_1089-1"
CHAIN_DENOM="uheart"
BINARY_NAME="humansd"
BINARY_VERSION_TAG="v1.0.0"
CHEAT_SHEET="https://nodejumper.io/humans-testnet/cheat-sheet"

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
rm -rf humans
git clone https://github.com/humansdotai/humans
cd humans || return
git checkout v1.0.0
make install
humansd version # 1.0.0

humansd init "$NODE_MONIKER" --chain-id $CHAIN_ID
humansd config chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/humansdotai/mainnets/main/mainnet/1/genesis_1089-1.json > $HOME/.humansd/config/genesis.json
curl -s https://snapshots.nodejumper.io/humans/addrbook.json > $HOME/.humansd/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.humansd/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.humansd/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.humansd/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.humansd/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.humansd/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.001aheart"|g' $HOME/.humansd/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.humansd/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/humansd.service > /dev/null << EOF
[Unit]
Description=Humans AI Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which humansd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

humansd tendermint unsafe-reset-all --home $HOME/.humansd --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots.nodejumper.io/humans/info.json | jq -r .fileName)
curl "https://snapshots.nodejumper.io/humans/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.humansd"

sudo systemctl daemon-reload
sudo systemctl enable humansd
sudo systemctl start humansd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
