#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="cascadia_6102-1"
CHAIN_DENOM="aCC"
BINARY_NAME="cascadiad"
BINARY_VERSION_TAG="v0.1.5"
CHEAT_SHEET="https://nodejumper.io/cascadia-testnet/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

curl -L https://github.com/CascadiaFoundation/cascadia/releases/download/v0.1.5/cascadiad -o cascadiad
chmod +x cascadiad
sudo mv cascadiad /usr/local/bin
cascadiad version # ac03925

cascadiad config keyring-backend test
cascadiad config chain-id $CHAIN_ID
cascadiad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -L https://github.com/CascadiaFoundation/chain-configuration/raw/master/testnet/genesis.json.gz -o ~/.cascadiad/config/genesis.zip
gunzip -c ~/.cascadiad/config/genesis.zip > ~/.cascadiad/config/genesis.json
rm -rf ~/.cascadiad/config/genesis.zip

curl -s https://snapshots-testnet.nodejumper.io/cascadia-testnet/addrbook.json > $HOME/.cascadiad/config/addrbook.json

SEEDS="42c4a78f39935df1c20b51c4b0d0a21db8f01c88@cascadia-testnet-seed.itrocket.net:40656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.cascadiad/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.cascadiad/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.cascadiad/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.cascadiad/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.cascadiad/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001aCC"|g' $HOME/.cascadiad/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.cascadiad/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/cascadiad.service > /dev/null << EOF
[Unit]
Description=Cascadia Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which cascadiad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

cascadiad tendermint unsafe-reset-all --home $HOME/.cascadiad --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/cascadia-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/cascadia-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.cascadiad"

sudo systemctl daemon-reload
sudo systemctl enable cascadiad
sudo systemctl start cascadiad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
