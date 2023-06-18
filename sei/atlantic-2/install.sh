#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="atlantic-2"
CHAIN_DENOM="usei"
BINARY_NAME="seid"
BINARY_VERSION_TAG="3.0.4"
CHEAT_SHEET="https://nodejumper.io/sei-testnet/cheat-sheet"

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
rm -rf sei-chain
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain || return
git checkout 3.0.4
make install
seid version # 3.0.4

seid config keyring-backend test
seid config chain-id $CHAIN_ID
seid init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/sei-protocol/testnet/main/atlantic-2/genesis.json > $HOME/.sei/config/genesis.json

SEEDS="f97a75fb69d3a5fe893dca7c8d238ccc0bd66a8f@sei-testnet-2.seed.brocha.in:30587,94b63fddfc78230f51aeb7ac34b9fb86bd042a77@sei-testnet-2.p2p.brocha.in:30588"
PEERS=""
sed -i 's|^bootstrap-peers *=.*|bootstrap-peers = "'$SEEDS'"|; s|^persistent-peers *=.*|persistent-peers = "'$PEERS'"|' $HOME/.sei/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.sei/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.sei/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.sei/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.sei/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001usei"|g' $HOME/.sei/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.sei/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/seid.service > /dev/null << EOF
[Unit]
Description=Sei Protocol Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which seid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

rm -rf ~/.sei/data
rm -rf ~/.sei/wasm

SNAP_NAME=$(curl -s https://snapshots2-testnet.nodejumper.io/sei-testnet/info.json | jq -r .fileName)
curl "https://snapshots2-testnet.nodejumper.io/sei-testnet/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.sei"

sudo systemctl daemon-reload
sudo systemctl enable seid
sudo systemctl start seid

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
