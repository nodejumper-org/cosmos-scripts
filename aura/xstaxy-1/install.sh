#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/common.sh)

printLogo

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="xstaxy-1"
CHAIN_DENOM="uaura"
BINARY_NAME="aurad"
CHEAT_SHEET="https://nodejumper.io/aura/cheat-sheet"
BINARY_VERSION_TAG="aura_v0.4.5"

printLine
echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd || return
rm -rf aura
git clone https://github.com/aura-nw/aura
cd aura || return
git checkout aura_v0.4.5
make install
aurad version # main_v0.4.5

aurad config chain-id $CHAIN_ID
aurad init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/aura-nw/mainnet-artifacts/main/xstaxy-1/genesis.json > $HOME/.aura/config/genesis.json
curl -s https://snapshots1.nodejumper.io/aura/addrbook.json > $HOME/.aura/config/addrbook.json

SEEDS="22a0ca5f64187bb477be1d82166b1e9e184afe50@18.143.52.13:26656,0b8bd8c1b956b441f036e71df3a4d96e85f843b8@13.250.159.219:26656"
PEERS=""
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.aura/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.aura/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.aura/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.aura/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.aura/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001uaura"|g' $HOME/.aura/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.aura/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/aurad.service > /dev/null << EOF
[Unit]
Description=Aura Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which aurad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

aurad tendermint unsafe-reset-all --home $HOME/.aura --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots1.nodejumper.io/aura/info.json | jq -r .fileName)
curl "https://snapshots1.nodejumper.io/aura/${SNAP_NAME}" | lz4 -dc - | tar -xf - -C "$HOME/.aura"

sudo systemctl daemon-reload
sudo systemctl enable aurad
sudo systemctl start aurad

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}"
