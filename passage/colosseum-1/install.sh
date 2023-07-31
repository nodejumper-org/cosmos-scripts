#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="passage-1"
CHAIN_DENOM="upasg"
BINARY_NAME="passage"
BINARY_VERSION_TAG="v1.1.0"
CHEAT_SHEET="https://nodejumper.io/passage/cheat-sheet"

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
rm -rf Passage3D
git clone https://github.com/envadiv/Passage3D.git
cd Passage3D || return
git checkout v1.1.0
make install
passage version # v1.1.0

passage config keyring-backend file
passage config chain-id $CHAIN_ID
passage init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/envadiv/mainnet/main/passage-1/genesis.json > $HOME/.passage/config/genesis.json
# TODO curl -s https://snapshots.nodejumper.io/passage/addrbook.json > $HOME/.passage/config/addrbook.json

SEEDS="aebb8431609cb126a977592446f5de252d8b7fa1@104.236.201.138:26656,b6beabfb9309330944f44a1686742c2751748b83@5.161.47.163:26656,7a9a36630523f54c1a0d56fc01e0e153fd11a53d@167.235.24.145:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.passage/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.passage/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.passage/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "17"|g' $HOME/.passage/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.passage/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.001upasg"|g' $HOME/.passage/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.passage/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/passaged.service > /dev/null << EOF
[Unit]
Description=Passage3D Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which passage) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# TODO: passage tendermint unsafe-reset-all --home $HOME/.passage --keep-addr-book
#
#SNAP_NAME=$(curl -s https://snapshots.nodejumper.io/passage/info.json | jq -r .fileName)
#curl "https://snapshots.nodejumper.io/passage/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.passage"

sudo systemctl daemon-reload
sudo systemctl enable passaged
sudo systemctl start passaged

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u passaged -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}passaged status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
