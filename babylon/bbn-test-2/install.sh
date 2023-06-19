#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="bbn-test-2"
CHAIN_DENOM="ubbn"
BINARY_NAME="babylond"
BINARY_VERSION_TAG="v0.7.2"
CHEAT_SHEET="https://nodejumper.io/babylon-testnet/cheat-sheet"

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
rm -rf babylon
git clone https://github.com/babylonchain/babylon
cd babylon || return
git checkout v0.7.2
make install
babylond version # v0.7.2

babylond config keyring-backend test
babylond config chain-id $CHAIN_ID
babylond init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -L https://github.com/babylonchain/networks/raw/main/bbn-test-2/genesis.tar.bz2 > genesis.tar.bz2
tar -xjf genesis.tar.bz2
rm genesis.tar.bz2
mv genesis.json ~/.babylond/config/genesis.json

curl -s https://snapshots1-testnet.nodejumper.io/babylon-testnet/addrbook.json > $HOME/.babylond/config/addrbook.json

SEEDS="8da45f9ff83b4f8dd45bbcb4f850999637fbfe3b@seed0.testnet.babylonchain.io:26656,4b1f8a774220ba1073a4e9f4881de218b8a49c99@seed1.testnet.babylonchain.io:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.babylond/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.babylond/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.babylond/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.babylond/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.babylond/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.00001ubbn"|g' $HOME/.babylond/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.babylond/config/config.toml
sed -i 's|^network *=.*|network = "mainnet"|g' $HOME/.babylond/config/app.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/babylond.service > /dev/null << EOF
[Unit]
Description=Babylon Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which babylond) start --x-crisis-skip-assert-invariants
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

babylond tendermint unsafe-reset-all --home $HOME/.babylond --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1-testnet.nodejumper.io/babylon-testnet/info.json | jq -r .fileName)
curl "https://snapshots1-testnet.nodejumper.io/babylon-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.babylond"

sudo systemctl daemon-reload
sudo systemctl enable babylond
sudo systemctl start babylond

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
