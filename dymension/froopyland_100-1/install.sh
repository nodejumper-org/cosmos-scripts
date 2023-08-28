#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="froopyland_100-1"
CHAIN_DENOM="udym"
BINARY_NAME="dymd"
BINARY_VERSION_TAG="v1.0.2-beta"
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
git checkout v1.0.2-beta
make install
dymd version # v1.0.2-beta

dymd config keyring-backend test
dymd config chain-id $CHAIN_ID
dymd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/dymensionxyz/testnets/main/dymension-hub/froopyland/genesis.json > $HOME/.dymension/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/dymension-testnet/addrbook.json > $HOME/.dymension/config/addrbook.json

SEEDS="ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20556,92308bad858b8886e102009bbb45994d57af44e7@rpc-t.dymension.nodestake.top:666,284313184f63d9f06b218a67a0e2de126b64258d@seeds.silknodes.io:26157"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.dymension/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.dymension/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.dymension/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.dymension/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.dymension/config/app.toml

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

SNAP_NAME=$(curl -s https://snapshots-testnet.nodejumper.io/dymension-testnet/info.json | jq -r .fileName)
curl "https://snapshots-testnet.nodejumper.io/dymension-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.dymension"

sudo systemctl daemon-reload
sudo systemctl enable dymd
sudo systemctl start dymd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
