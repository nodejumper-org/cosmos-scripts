#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="provider"
CHAIN_DENOM="uatom"
BINARY_NAME="gaiad"
BINARY_VERSION_TAG="v9.0.0-rc2"
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

curl -L https://github.com/cosmos/gaia/releases/download/v9.0.0-rc7/gaiad-v9.0.0-rc7-linux-amd64 > gaiad
chmod +x gaiad
sudo mv gaiad /usr/local/bin
gaiad version # v9.0.0-rc7

gaiad config keyring-backend test
gaiad config chain-id $CHAIN_ID
gaiad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/cosmos/testnets/master/replicated-security/provider/provider-genesis.json > $HOME/.gaia/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/cosmos-testnet/addrbook.json > $HOME/.gaia/config/addrbook.json

SEEDS="08ec17e86dac67b9da70deb20177655495a55407@provider-seed-01.rs-testnet.polypore.xyz:26656,4ea6e56300a2f37b90e58de5ee27d1c9065cf871@provider-seed-02.rs-testnet.polypore.xyz:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.gaia/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.gaia/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.gaia/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.gaia/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.gaia/config/app.toml

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

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/cosmos-testnet/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/cosmos-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.gaia"

sudo systemctl daemon-reload
sudo systemctl enable gaiad
sudo systemctl start gaiad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
