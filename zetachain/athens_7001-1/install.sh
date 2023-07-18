#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="athens_7001-1"
CHAIN_DENOM="azeta"
BINARY_NAME="zetacored"
BINARY_VERSION_TAG="v5.0.0"
CHEAT_SHEET="https://nodejumper.io/zetachain-testnet/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

mkdir -p $HOME/go/bin
curl -L https://zetachain-external-files.s3.amazonaws.com/binaries/athens3/v5.0.0/zetacored-ubuntu-20-amd64 > $HOME/go/bin/zetacored
chmod +x $HOME/go/bin/zetacored

zetacored config chain-id $CHAIN_ID
zetacored config keyring-backend test
zetacored init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -L https://raw.githubusercontent.com/zeta-chain/network-athens3/main/network_files/config/genesis.json > $HOME/.zetacored/config/genesis.json
curl -L https://snapshots1-testnet.nodejumper.io/zetachain-testnet/addrbook.json > $HOME/.zetacored/config/addrbook.json

SEEDS="3f472746f46493309650e5a033076689996c8881@zetachain-testnet.rpc.kjnodes.com:16059"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.zetacored/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.zetacored/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.zetacored/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.zetacored/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.zetacored/config/app.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001azeta"|g' $HOME/.zetacored/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.zetacored/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/zetacored.service > /dev/null << EOF
[Unit]
Description=ZetaChain Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which zetacored) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
WorkingDirectory=$HOME
[Install]
WantedBy=multi-user.target
EOF

zetacored tendermint unsafe-reset-all --home $HOME/.zetacored --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/zetachain-testnet/info.json | jq -r .fileName)
curl "https://snapshots1-testnet.nodejumper.io/zetachain-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.zetacored"

sudo systemctl daemon-reload
sudo systemctl enable zetacored
sudo systemctl start zetacored

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
