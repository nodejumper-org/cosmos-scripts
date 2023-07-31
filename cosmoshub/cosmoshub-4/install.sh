#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="cosmoshub-4"
CHAIN_DENOM="uatom"
BINARY_NAME="gaiad"
BINARY_VERSION_TAG="v9.0.0"
CHEAT_SHEET="https://nodejumper.io/cosmos-testnet/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd $HOME || return
rm -rf gaia
git clone https://github.com/cosmos/gaia.git
cd gaia || return
git checkout v9.0.0
make install

gaiad config chain-id $CHAIN_ID
gaiad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/cosmos/mainnet/master/genesis/genesis.json > $HOME/.gaia/config/genesis.json
curl -s https://dl2.quicksync.io/json/addrbook.cosmos.json > $HOME/.gaia/config/addrbook.json

SEEDS=""
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.gaia/config/config.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|g' \
  -e 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' \
  -e 's|^pruning-interval *=.*|pruning-interval = "10"|g' \
  -e 's|^snapshot-interval *=.*|snapshot-interval = 0|g' \
  $HOME/.gaia/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uatom"|g' $HOME/.gaia/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.gaia/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/gaiad.service > /dev/null << EOF
[Unit]
Description=Cosmos Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which gaiad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

gaiad tendermint unsafe-reset-all --home $HOME/.gaia --keep-addr-book

# TODO: use own snap
curl -L https://snapshots.kjnodes.com/cosmoshub/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.gaia

# SNAP_NAME=$(curl -s https://snapshots.nodejumper.io/cosmoshub/info.json | jq -r .fileName)
# curl "https://snapshots.nodejumper.io/cosmoshub/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.gaia"

sudo systemctl daemon-reload
sudo systemctl enable gaiad
sudo systemctl start gaiad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
