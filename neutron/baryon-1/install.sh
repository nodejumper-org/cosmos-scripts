#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="baryon-1"
CHAIN_DENOM="untrn"
BINARY_NAME="neutrond"
BINARY_VERSION_TAG="v0.3.1"
CHEAT_SHEET="https://nodejumper.io/neutron-testnet/cheat-sheet"

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
rm -rf neutron
git clone https://github.com/neutron-org/neutron.git
cd neutron || return
git checkout v0.3.1.sh
make install
neutrond version # v0.3.1.sh

neutrond config keyring-backend test
neutrond config chain-id $CHAIN_ID
neutrond init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/neutron-org/cosmos-testnets/master/replicated-security/baryon-1/baryon-1-genesis.json > $HOME/.neutrond/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/neutron-testnet/addrbook.json > $HOME/.neutrond/config/addrbook.json

SEEDS="e2c07e8e6e808fb36cca0fc580e31216772841df@p2p.baryon.ntrn.info:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.neutrond/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.neutrond/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.neutrond/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.neutrond/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.neutrond/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001untrn"|g' $HOME/.neutrond/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.neutrond/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/neutrond.service > /dev/null << EOF
[Unit]
Description=Neutron Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which neutrond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

neutrond tendermint unsafe-reset-all --home $HOME/.neutrond --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/neutron-testnet/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/neutron-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.neutrond"

sudo systemctl daemon-reload
sudo systemctl enable neutrond
sudo systemctl start neutrond

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
