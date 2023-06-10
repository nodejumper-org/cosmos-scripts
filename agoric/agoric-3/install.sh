#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="agoric-3"
CHAIN_DENOM="ubld"
BINARY_NAME="agd"
BINARY_VERSION_TAG="pismoD"
CHEAT_SHEET="https://nodejumper.io/agoric/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

curl -Ls https://deb.nodesource.com/setup_16.x | sudo bash
curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt update
sudo apt install -y nodejs=16.* yarn

cd || return
rm -rf agoric-sdk
git clone https://github.com/Agoric/agoric-sdk.git
cd agoric-sdk || return
git checkout pismoD
yarn install
yarn build
cd packages/cosmic-swingset || return
make install
agd version # 0.33.0

agd config chain-id $CHAIN_ID
agd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://main.rpc.agoric.net/genesis | jq .result.genesis > $HOME/.agoric/config/genesis.json
curl -s https://snapshots2.nodejumper.io/agoric/addrbook.json > $HOME/.agoric/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.agoric/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.agoric/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.agoric/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.agoric/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.agoric/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ubld"|g' $HOME/.agoric/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.agoric/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/agd.service > /dev/null << EOF
[Unit]
Description=Agoric Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which agd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

agd tendermint unsafe-reset-all --home $HOME/.agoric --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2.nodejumper.io/agoric/info.json | jq -r .fileName)
curl "https://snapshots2.nodejumper.io/agoric/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.agoric"

sudo systemctl daemon-reload
sudo systemctl enable agd
sudo systemctl start agd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
