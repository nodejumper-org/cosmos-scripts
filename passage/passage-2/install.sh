#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="passage-2"
CHAIN_DENOM="upasg"
BINARY_NAME="passage"
BINARY_VERSION_TAG="v2.0.0"
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
git clone https://github.com/envadiv/Passage3D
cd Passage3D || return
git checkout v2.0.0
make install
passage version # v2.0.0

passage config chain-id $CHAIN_ID
passage config keyring-backend file
passage init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -L https://raw.githubusercontent.com/envadiv/mainnet/main/passage-2/genesis.json > $HOME/.passage/config/genesis.json
curl -s https://snapshots.nodejumper.io/passage/addrbook.json > $HOME/.passage/config/addrbook.json

SEEDS="ad9f93c38fafff854cdd65741df556d043dd6edb@5.161.71.7:26656,fbdcc82eeacc81f9ef7d77d22120f4567457c850@5.161.184.142:26656,df949a46ae6529ae1e09b034b49716468d5cc7e9@seeds.stakerhouse.com:10556"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.passage/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.passage/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.passage/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.passage/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.passage/config/app.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001upsg"|g' $HOME/.passage/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.passage/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/passage.service > /dev/null << EOF
[Unit]
Description=Passage3D Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which passage) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
WorkingDirectory=$HOME/.passage
[Install]
WantedBy=multi-user.target
EOF

passage tendermint unsafe-reset-all --home $HOME/.passage --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots.nodejumper.io/passage/info.json | jq -r .fileName)
curl "https://snapshots.nodejumper.io/passage/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.passage"

sudo systemctl daemon-reload
sudo systemctl enable passage
sudo systemctl start passage

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
