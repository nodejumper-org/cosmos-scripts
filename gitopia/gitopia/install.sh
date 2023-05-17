#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="gitopia"
CHAIN_DENOM="ulore"
BINARY_NAME="gitopiad"
BINARY_VERSION_TAG="v2.0.0"
CHEAT_SHEET="https://nodejumper.io/gitopia/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

# Clone project repository
cd $HOME || return
rm -rf gitopia
git clone https://github.com/gitopia/gitopia.git
cd gitopia || return
git checkout v2.0.0
make install

gitopiad init "$NODE_MONIKER" --chain-id $CHAIN_ID
gitopiad config chain-id $CHAIN_ID
gitopiad config keyring-backend file

cd || return
curl -sL https://github.com/gitopia/mainnet/raw/master/genesis.tar.gz > $HOME/genesis.tar.gz
tar -xzf $HOME/genesis.tar.gz
rm $HOME/genesis.tar.gz
rm $HOME/.gitopia/config/genesis.json
mv genesis.json $HOME/.gitopia/config/genesis.json

curl -s https://snapshots2.nodejumper.io/gitopia/addrbook.json > $HOME/.gitopia/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.gitopia/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.gitopia/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.gitopia/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "17"|g' $HOME/.gitopia/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.gitopia/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001ulore"|g' $HOME/.gitopia/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.gitopia/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/gitopiad.service > /dev/null << EOF
[Unit]
Description=Gitopia Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which gitopiad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

gitopiad tendermint unsafe-reset-all --home $HOME/.gitopia --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2.nodejumper.io/gitopia/info.json | jq -r .fileName)
curl "https://snapshots2.nodejumper.io/gitopia/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.gitopia"

sudo systemctl daemon-reload
sudo systemctl enable gitopiad
sudo systemctl start gitopiad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
