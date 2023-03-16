#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="okp4-nemeton-1"
CHAIN_DENOM="uknow"
BINARY_NAME="okp4d"
BINARY_VERSION_TAG="v4.1.0"
CHEAT_SHEET="https://nodejumper.io/okp4-testnet/cheat-sheet"

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
rm -rf okp4d
git clone https://github.com/okp4/okp4d.git
cd okp4d || return
git checkout v4.1.0
make install
okp4d version # 4.1.0

okp4d config keyring-backend test
okp4d config chain-id $CHAIN_ID
okp4d init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/okp4/networks/main/chains/nemeton-1/genesis.json > $HOME/.okp4d/config/genesis.json
curl -s https://snapshots1-testnet.nodejumper.io/okp4-testnet/addrbook.json > $HOME/.okp4d/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.okp4d/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.okp4d/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.okp4d/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.okp4d/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.okp4d/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uknow"|g' $HOME/.okp4d/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.okp4d/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/okp4d.service > /dev/null << EOF
[Unit]
Description=OKP4 Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which okp4d) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

okp4d tendermint unsafe-reset-all --home $HOME/.okp4d --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/okp4-testnet/info.json | jq -r .fileName)
curl "https://snapshots1-testnet.nodejumper.io/okp4-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.okp4d"

sudo systemctl daemon-reload
sudo systemctl enable okp4d
sudo systemctl start okp4d

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
