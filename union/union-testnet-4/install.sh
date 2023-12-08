#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="union-testnet-4"
CHAIN_DENOM="muno"
BINARY_NAME="uniond"
CHEAT_SHEET="https://nodejumper.io/union-testnet/cheat-sheet"
BINARY_VERSION_TAG="v0.15.0"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

mkdir -p "$HOME/go/bin"
curl -L# https://snapshots-testnet.nodejumper.io/union-testnet/uniond-0.15.0-linux-amd64 > $HOME/go/bin/uniond
sudo chmod +x $HOME/go/bin/uniond

uniond config chain-id $CHAIN_ID
uniond config keyring-backend test
uniond init "$NODE_MONIKER" bn254 --chain-id $CHAIN_ID

curl -Ls https://snapshots-testnet.nodejumper.io/union-testnet/genesis.json > $HOME/.union/config/genesis.json
curl -Ls https://snapshots-testnet.nodejumper.io/union-testnet/addrbook.json > $HOME/.union/config/addrbook.json

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0muno"|g' $HOME/.union/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|g' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|g' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|g' \
  $HOME/.union/config/app.toml

SEEDS="3f472746f46493309650e5a033076689996c8881@union-testnet.rpc.kjnodes.com:17159"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|' $HOME/.union/config/config.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.union/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/uniond.service > /dev/null << EOF
[Unit]
Description=Union Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which uniond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

uniond tendermint unsafe-reset-all --home $HOME/.union --keep-addr-book

curl -L# "https://snapshots-testnet.nodejumper.io/union-testnet/union-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.union"

sudo systemctl daemon-reload
sudo systemctl enable uniond
sudo systemctl start uniond

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
