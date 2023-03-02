#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="35-C"
CHAIN_DENOM="udym"
BINARY_NAME="dymd"
BINARY_VERSION_TAG="v0.2.0-beta"
CHEAT_SHEET="https://nodejumper.io/dymension-testnet/cheat-sheet"

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
rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension || return
git checkout v0.2.0-beta
make install
dymd version # v0.2.0-beta

dymd config keyring-backend test
dymd config chain-id $CHAIN_ID
dymd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/dymensionxyz/testnets/main/dymension-hub/35-C/genesis.json > $HOME/.dymension/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/dymension-testnet/addrbook.json > $HOME/.dymension/config/addrbook.json

SEEDS="f97a75fb69d3a5fe893dca7c8d238ccc0bd66a8f@dymension-testnet.seed.brocha.in:30584,ebc272824924ea1a27ea3183dd0b9ba713494f83@dymension-testnet-seed.autostake.net:27086,b78dd0e25e28ec0b43412205f7c6780be8775b43@dym.seed.takeshi.team:10356,babc3f3f7804933265ec9c40ad94f4da8e9e0017@testnet-seed.rhinostake.com:20556,c6cdcc7f8e1a33f864956a8201c304741411f219@3.214.163.125:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.dymension/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.dymension/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.dymension/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.dymension/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.dymension/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001udym"|g' $HOME/.dymension/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.dymension/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/dymd.service > /dev/null << EOF
[Unit]
Description=Dymension testnet Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which dymd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

dymd tendermint unsafe-reset-all --home $HOME/.dymension --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/dymension-testnet/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/dymension-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.dymension"

sudo systemctl daemon-reload
sudo systemctl enable dymd
sudo systemctl start dymd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
