#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="nolus-rila"
CHAIN_DENOM="unls"
BINARY_NAME="nolusd"
BINARY_VERSION_TAG="v0.1.43"
CHEAT_SHEET="https://nodejumper.io/nolus-testnet/cheat-sheet"

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
rm -rf nolus-core
git clone https://github.com/Nolus-Protocol/nolus-core.git
cd nolus-core || return
git checkout v0.1.43
make install
nolusd version # 0.1.43

nolusd config keyring-backend test
nolusd config chain-id $CHAIN_ID
nolusd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/Nolus-Protocol/nolus-networks/main/testnet/nolus-rila/genesis.json > $HOME/.nolus/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/nolus-testnet/addrbook.json > $HOME/.nolus/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.nolus/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.nolus/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.nolus/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.nolus/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.nolus/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001unls"|g' $HOME/.nolus/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.nolus/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/nolusd.service > /dev/null << EOF
[Unit]
Description=Nolus Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which nolusd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

nolusd tendermint unsafe-reset-all --home $HOME/.nolus --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/nolus-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/nolus-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.nolus"

sudo systemctl daemon-reload
sudo systemctl enable nolusd
sudo systemctl start nolusd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
